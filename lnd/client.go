// Copyright (c) 2013-2017 The btcsuite developers
// Copyright (c) 2015-2016 The Decred developers
// Copyright (C) 2015-2017 The Lightning Network Developers

package lnd

import (
	"log"
	"net"
	"time"

	"google.golang.org/grpc"
	"github.com/lightningnetwork/lnd/channeldb"
	"fmt"
	"github.com/lightningnetwork/lnd/lnwallet/btcwallet"
	"github.com/roasbeef/btcd/chaincfg"
	"github.com/lightningnetwork/lnd/lnwallet"
	base "github.com/roasbeef/btcwallet/wallet"
	"github.com/lightninglabs/neutrino"
	"github.com/lightningnetwork/lnd/chainntnfs/neutrinonotify"
	"github.com/lightningnetwork/lnd/routing/chainview"
	"github.com/roasbeef/btcwallet/chain"
	"github.com/roasbeef/btcwallet/walletdb"
	"path/filepath"
	"github.com/roasbeef/btcd/btcec"
	"github.com/lightningnetwork/lnd/lnwire"
	"github.com/roasbeef/btcutil"
	"github.com/lightningnetwork/lnd/lnrpc"
	"crypto/rand"
	"strconv"
	"sync"
)

var (
	registeredChains = newChainRegistry()

	chanDB			 *channeldb.DB
	cfg              *config
	shutdownChannel  = make(chan struct{})

	macaroonDatabaseDir string

)

// Controls access to lightningRpcServer.
var rpcServerMutex = &sync.Mutex{}

var s *grpc.Server
var lightningRpcServer *rpcServer

// Start the grpc server.
func Start(dataDir string, seed []byte) error {
	log.Print("Starting backend")

	initLogRotator(filepath.Join(dataDir, defaultLogFilename))

	setLogLevels("TRACE")
	setLogLevel("BTCN", "DEBUG")

	cfg = &config{
		ConfigFile:          defaultConfigFile,
		DataDir:             defaultDataDir,
		DebugLevel:          defaultLogLevel,
		TLSCertPath:         defaultTLSCertPath,
		TLSKeyPath:          defaultTLSKeyPath,
		AdminMacPath:        defaultAdminMacPath,
		ReadMacPath:         defaultReadMacPath,
		LogDir:              defaultLogDir,
		PeerPort:            defaultPeerPort,
		RPCPort:             defaultRPCPort,
		RESTPort:            defaultRESTPort,
		MaxPendingChannels:  defaultMaxPendingChannels,
		DefaultNumChanConfs: defaultNumChanConfs,
		NoEncryptWallet:     defaultNoEncryptWallet,
		Bitcoin: &chainConfig{
			RPCHost: defaultRPCHost,
			RPCCert: defaultBtcdRPCCertFile,
		},
		Litecoin: &chainConfig{
			RPCHost: defaultRPCHost,
			RPCCert: defaultLtcdRPCCertFile,
		},
		Autopilot: &autoPilotConfig{
			MaxChannels: 5,
			Allocation:  0.6,
		},
		TrickleDelay: defaultTrickleDelay,
	}

	// Open the channeldb, which is dedicated to storing channel, and
	// network related metadata.
	var err error
	chanDB, err = channeldb.Open(dataDir)
	if err != nil {
		log.Printf("unable to open channeldb: %v", err)
		return err
	}

	// With the information parsed from the configuration, create valid
	// instances of the pertinent interfaces required to operate the
	// Lightning Network Daemon.
	activeChainControl, _, err := newChainControlFromConfig2(chanDB, dataDir, seed)
	if err != nil {
		fmt.Printf("unable to create chain control: %v\n", err)
		return err
	}

	primaryChain := registeredChains.PrimaryChain()
	registeredChains.RegisterChain(primaryChain, activeChainControl)

	idPrivKey, err := activeChainControl.wallet.GetIdentitykey()
	if err != nil {
		return err
	}
	idPrivKey.Curve = btcec.S256()

	// Set up the core server which will listen for incoming peer
	// connections.
	defaultListenAddrs := []string{
		net.JoinHostPort("", strconv.Itoa(9735)),
	}
	server, err := newServer(defaultListenAddrs, chanDB, activeChainControl,
		idPrivKey)
	if err != nil {
		srvrLog.Errorf("unable to create server: %v\n", err)
		return err
	}

	// Next, we'll initialize the funding manager itself so it can answer
	// queries while the wallet+chain are still syncing.
	nodeSigner := newNodeSigner(idPrivKey)
	var chanIDSeed [32]byte
	if _, err := rand.Read(chanIDSeed[:]); err != nil {
		return err
	}
	fundingMgr, err := newFundingManager(fundingConfig{
		IDKey:        idPrivKey.PubKey(),
		Wallet:       activeChainControl.wallet,
		Notifier:     activeChainControl.chainNotifier,
		FeeEstimator: activeChainControl.feeEstimator,
		SignMessage: func(pubKey *btcec.PublicKey,
			msg []byte) (*btcec.Signature, error) {

			if pubKey.IsEqual(idPrivKey.PubKey()) {
				return nodeSigner.SignMessage(pubKey, msg)
			}

			return activeChainControl.msgSigner.SignMessage(
				pubKey, msg,
			)
		},
		CurrentNodeAnnouncement: func() (lnwire.NodeAnnouncement, error) {
			return server.genNodeAnnouncement(true)
		},
		SendAnnouncement: func(msg lnwire.Message) error {
			errChan := server.authGossiper.ProcessLocalAnnouncement(msg,
				idPrivKey.PubKey())
			return <-errChan
		},
		ArbiterChan:      server.breachArbiter.newContracts,
		SendToPeer:       server.SendToPeer,
		NotifyWhenOnline: server.NotifyWhenOnline,
		FindPeer:         server.FindPeer,
		TempChanIDSeed:   chanIDSeed,
		FindChannel: func(chanID lnwire.ChannelID) (*lnwallet.LightningChannel, error) {
			dbChannels, err := chanDB.FetchAllChannels()
			if err != nil {
				return nil, err
			}

			for _, channel := range dbChannels {
				if chanID.IsChanPoint(&channel.FundingOutpoint) {
					return lnwallet.NewLightningChannel(
						activeChainControl.signer,
						activeChainControl.chainNotifier,
						activeChainControl.feeEstimator,
						channel)
				}
			}

			return nil, fmt.Errorf("unable to find channel")
		},
		DefaultRoutingPolicy: activeChainControl.routingPolicy,
		NumRequiredConfs: func(chanAmt btcutil.Amount,
			pushAmt lnwire.MilliSatoshi) uint16 {
			// For large channels we increase the number
			// of confirmations we require for the
			// channel to be considered open. As it is
			// always the responder that gets to choose
			// value, the pushAmt is value being pushed
			// to us. This means we have more to lose
			// in the case this gets re-orged out, and
			// we will require more confirmations before
			// we consider it open.
			// TODO(halseth): Use Litecoin params in case
			// of LTC channels.

			// In case the user has explicitly specified
			// a default value for the number of
			// confirmations, we use it.
			defaultConf := uint16(cfg.Bitcoin.DefaultNumChanConfs)
			if defaultConf != 0 {
				return defaultConf
			}

			// If not we return a value scaled linearly
			// between 3 and 6, depending on channel size.
			// TODO(halseth): Use 1 as minimum?
			minConf := uint64(3)
			maxConf := uint64(6)
			maxChannelSize := uint64(
				lnwire.NewMSatFromSatoshis(maxFundingAmount))
			stake := lnwire.NewMSatFromSatoshis(chanAmt) + pushAmt
			conf := maxConf * uint64(stake) / maxChannelSize
			if conf < minConf {
				conf = minConf
			}
			if conf > maxConf {
				conf = maxConf
			}
			return uint16(conf)
		},
		RequiredRemoteDelay: func(chanAmt btcutil.Amount) uint16 {
			// We scale the remote CSV delay (the time the
			// remote have to claim funds in case of a unilateral
			// close) linearly from minRemoteDelay blocks
			// for small channels, to maxRemoteDelay blocks
			// for channels of size maxFundingAmount.
			// TODO(halseth): Litecoin parameter for LTC.

			// In case the user has explicitly specified
			// a default value for the remote delay, we
			// use it.
			defaultDelay := uint16(cfg.Bitcoin.DefaultRemoteDelay)
			if defaultDelay > 0 {
				return defaultDelay
			}

			// If not we scale according to channel size.
			delay := uint16(maxRemoteDelay *
				chanAmt / maxFundingAmount)
			if delay < minRemoteDelay {
				delay = minRemoteDelay
			}
			if delay > maxRemoteDelay {
				delay = maxRemoteDelay
			}
			return delay
		},
	})
	if err != nil {
		return err
	}
	if err := fundingMgr.Start(); err != nil {
		return err
	}
	server.fundingMgr = fundingMgr

	log.Print("Starting lightningRpcServer")

	// Initialize, and register our implementation of the gRPC interface
	// exported by the rpcServer.
	rpcServerMutex.Lock()
	defer rpcServerMutex.Unlock()
	lightningRpcServer = newRPCServer(server, nil)
	if err := lightningRpcServer.Start(); err != nil {
		log.Printf("Failed to start lightningRpcServer=%v", err)

		return err
	}

	log.Printf("Started lightningRpcServer=%v", lightningRpcServer)

	// FIXME(simon): Here we block until the wallet is synced. This is bad.
	go func() error {
		// If we're not in simnet mode, We'll wait until we're fully synced to
		// continue the start up of the remainder of the daemon. This ensures
		// that we don't accept any possibly invalid state transitions, or
		// accept channels with spent funds.

		_, bestHeight, err := activeChainControl.chainIO.GetBestBlock()
		if err != nil {
			return err
		}

		ltndLog.Infof("Waiting for chain backend to finish sync, "+
			"start_height=%v", bestHeight)

		for {
			synced, err := activeChainControl.wallet.IsSynced()
			if err != nil {
				srvrLog.Errorf("unable to create to sync server: %v\n", err)
				return err
			}

			if synced {
				break
			}

			time.Sleep(time.Second * 1)
		}

		_, bestHeight, err = activeChainControl.chainIO.GetBestBlock()
		if err != nil {
			return err
		}

		ltndLog.Infof("Chain backend is fully synced (end_height=%v)!",
			bestHeight)

		// With all the relevant chains initialized, we can finally start the
		// server itself.
		if err := server.Start(); err != nil {
			srvrLog.Errorf("unable to create to start server: %v\n", err)
			return err
		}

		// Force autopilot.
		cfg.Autopilot.Active = true
		cfg.Autopilot.Allocation = 0.9
		cfg.Autopilot.MaxChannels = 3

		// Now that the server has started, if the autopilot mode is currently
		// active, then we'll initialize a fresh instance of it and start it.
		if cfg.Autopilot.Active {
			pilot, err := initAutoPilot(server, cfg.Autopilot)
			if err != nil {
				ltndLog.Errorf("unable to create autopilot agent: %v",
					err)
				return err
			}
			if err := pilot.Start(); err != nil {
				ltndLog.Errorf("unable to start autopilot agent: %v",
					err)
				return err
			}
		}

		return nil
	}()

	log.Print("Returning from Start")

	return nil
}

func Pause() {
	// Kills the gRPC server and any tcp connections.
	s.Stop()
	s = nil
}

func Resume() {
	log.Print("Resume")

	// Create a new grpc server here, because grpc doesn't support resuming previous instances.
	s = grpc.NewServer()

	for {
		rpcServerMutex.Lock()

		log.Printf("lightningRpcServer=%v", lightningRpcServer)

		// Wait until we have an rpc server.
		if lightningRpcServer != nil {
			rpcServerMutex.Unlock()
			break
		}
		rpcServerMutex.Unlock()

		log.Print("Waiting for lightningRpcServer")

		time.Sleep(10 * time.Second)
	}

	log.Printf("Registering lightningRpcServer=%v", lightningRpcServer)

	lnrpc.RegisterLightningServer(s, lightningRpcServer)

	// Start the gRPC server listening for HTTP/2 connections.
	lis, err := net.Listen("tcp", "localhost:10009")
	if err != nil {
		log.Printf("failed to listen: %v", err)
	}
	go func() {
		rpcsLog.Infof("RPC server listening on %s", lis.Addr())
		log.Printf("grpc server quit: %v", s.Serve(lis))
	}()
}

func Stop() {
	chanDB.Close()
}

func WalletExists(dataDir string) bool {
	network := chaincfg.TestNet3Params

	netDir := btcwallet.NetworkDir(dataDir, &network)

	loader := base.NewLoader(&network, netDir)
	walletExists, err := loader.WalletExists()
	if err != nil {
		log.Printf("Failed to read wallet: %v", err)
		return true
	}

	return walletExists
}

func newChainControlFromConfig2(chanDB *channeldb.DB, dataDir string, seed []byte) (*chainControl, func(), error) {
	privateWalletPw := []byte("hello")
	publicWalletPw := []byte("public")

	cc := &chainControl{}

	feeEstimator := lnwallet.StaticFeeEstimator{
		FeeRate: 50,
	}

	cc.feeEstimator = feeEstimator
	cc.routingPolicy = defaultBitcoinForwardingPolicy

	network := chaincfg.TestNet3Params

	var (
		err     error
		cleanUp func()
	)

	walletConfig := &btcwallet.Config{
		PrivatePass:  privateWalletPw,
		PublicPass:   publicWalletPw,
		DataDir:      dataDir,
		NetParams:    &network,
		FeeEstimator: feeEstimator,
		HdSeed:       seed,
	}

	// First we'll open the database file for neutrino, creating
	// the database if needed.
	dbName := filepath.Join(dataDir, "neutrino.db")
	nodeDatabase, err := walletdb.Create("bdb", dbName)
	if err != nil {
		return nil, nil, err
	}

	// With the database open, we can now create an instance of the
	// neutrino light client. We pass in relevant configuration
	// parameters required.
	config := neutrino.Config{
		DataDir:      dataDir,
		Database:     nodeDatabase,
		ChainParams:  network,
		AddPeers:     []string{},
		ConnectPeers: []string{"sg.horlick.me:18333"},
	}
	neutrino.WaitForMoreCFHeaders = time.Second * 1
	neutrino.MaxPeers = 8
	neutrino.BanDuration = 5 * time.Second
	svc, err := neutrino.NewChainService(config)
	if err != nil {
		return nil, nil, fmt.Errorf("unable to create neutrino: %v", err)
	}
	svc.Start()

	// Next we'll create the instances of the ChainNotifier and
	// FilteredChainView interface which is backed by the neutrino
	// light client.
	cc.chainNotifier, err = neutrinonotify.New(svc)
	if err != nil {
		return nil, nil, err
	}
	cc.chainView, err = chainview.NewCfFilteredChainView(svc)
	if err != nil {
		return nil, nil, err
	}

	// Finally, we'll set the chain source for btcwallet, and
	// create our clean up function which simply closes the
	// database.
	walletConfig.ChainSource = chain.NewNeutrinoClient(svc)
	cleanUp = func() {
		defer nodeDatabase.Close()
	}

	// FIXME(simon): We want to be able to show the user a BIP39 mnemonic
	// when we first generate the wallet.
	wc, err := btcwallet.New(*walletConfig)
	if err != nil {
		fmt.Printf("unable to create wallet controller: %v\n", err)
		return nil, nil, err
	}

	cc.msgSigner = wc
	cc.signer = wc
	cc.chainIO = wc

	var defaultChannelConstraints = channeldb.ChannelConstraints{
		DustLimit:        lnwallet.DefaultDustLimit(),
		MaxAcceptedHtlcs: lnwallet.MaxHTLCNumber / 2,
	}

	// Create, and start the lnwallet, which handles the core payment
	// channel logic, and exposes control via proxy state machines.
	walletCfg := lnwallet.Config{
		Database:           chanDB,
		Notifier:           cc.chainNotifier,
		WalletController:   wc,
		Signer:             cc.signer,
		FeeEstimator:       feeEstimator,
		ChainIO:            cc.chainIO,
		DefaultConstraints: defaultChannelConstraints,
		NetParams:          network,
	}

	wallet, err := lnwallet.NewLightningWallet(walletCfg)
	if err != nil {
		fmt.Printf("unable to create wallet: %v\n", err)
		return nil, nil, err
	}
	if err := wallet.Startup(); err != nil {
		fmt.Printf("unable to start wallet: %v\n", err)
		return nil, nil, err
	}

	log.Println("LightningWallet opened")

	cc.wallet = wallet

	return cc, cleanUp, nil

}
