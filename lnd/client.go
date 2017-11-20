package lnd

import (
	"log"
	"net"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/test/bufconn"
	"github.com/lightningnetwork/lnd/channeldb"
	"fmt"
	"github.com/lightningnetwork/lnd/lnwallet/btcwallet"
	"github.com/roasbeef/btcd/chaincfg"
	"github.com/lightningnetwork/lnd/lnwallet"
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
)

var (
	registeredChains = newChainRegistry()

	chanDB			 *channeldb.DB
	cfg              *config
	shutdownChannel  = make(chan struct{})

	macaroonDatabaseDir string

)

var s *grpc.Server
var lis = bufconn.Listen(1024 * 1024)
var dialer = func(string, time.Duration) (net.Conn, error) { return lis.Dial() }

// Start the grpc server.
func Start(dataDir string) error {
	if s != nil {
		log.Print("Backend already started")
		return nil
	}
	log.Print("Starting backend")

	s = grpc.NewServer()

	initLogRotator(filepath.Join(dataDir, defaultLogFilename))

	setLogLevels("DEBUG")

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
	activeChainControl, _, err := newChainControlFromConfig2(chanDB, dataDir)
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
		NumRequiredConfs: func(chanAmt btcutil.Amount, pushAmt lnwire.MilliSatoshi) uint16 {
			// TODO(roasbeef): add configurable mapping
			//  * simple switch initially
			//  * assign coefficient, etc
			return uint16(defaultNumChanConfs)
		},
		RequiredRemoteDelay: func(chanAmt btcutil.Amount) uint16 {
			// TODO(roasbeef): add additional hooks for
			// configuration
			return 4
		},
	})
	if err != nil {
		return err
	}
	if err := fundingMgr.Start(); err != nil {
		return err
	}
	server.fundingMgr = fundingMgr

	// Initialize, and register our implementation of the gRPC interface
	// exported by the rpcServer.
	rpcServer := newRPCServer(server, nil)
	//if err := rpcServer.Start(); err != nil {
	//	return err
	//}

	//grpcServer := grpc.NewServer(serverOpts...)
	lnrpc.RegisterLightningServer(s, rpcServer)

	 //Next, Start the gRPC server listening for HTTP/2 connections.
	//lis, err := net.Listen("tcp", grpcEndpoint)
	//if err != nil {
	//	fmt.Printf("failed to listen: %v", err)
	//	return err
	//}
	//go func() {
	//	rpcsLog.Infof("RPC server listening on %s", lis.Addr())
	//	grpcServer.Serve(lis)
	//}()
	// Finally, start the REST proxy for our gRPC server above.
	//ctx := context.Background()
	//ctx, cancel := context.WithCancel(ctx)
	//defer cancel()

	//mux := proxy.NewServeMux()
	//err = lnrpc.RegisterLightningHandlerFromEndpoint(ctx, mux, grpcEndpoint,
	//	proxyOpts)
	//if err != nil {
	//	return err
	//}
	//go func() {
	//	listener, err := tls.Listen("tcp", restEndpoint, tlsConf)
	//	if err != nil {
	//		ltndLog.Errorf("gRPC proxy unable to listen on "+
	//			"localhost%s", restEndpoint)
	//		return
	//	}
	//	rpcsLog.Infof("gRPC proxy started at localhost%s", restEndpoint)
	//	http.Serve(listener, mux)
	//}()

	// If we're not in simnet mode, We'll wait until we're fully synced to
	// continue the start up of the remainder of the daemon. This ensures
	// that we don't accept any possibly invalid state transitions, or
	// accept channels with spent funds.

	go func() {
		if true {
			_, bestHeight, err := activeChainControl.chainIO.GetBestBlock()
			if err != nil {
				return
			}

			ltndLog.Infof("Waiting for chain backend to finish sync, "+
				"start_height=%v", bestHeight)

			for {
				synced, err := activeChainControl.wallet.IsSynced()
				if err != nil {
					srvrLog.Errorf("unable to create to sync server: %v\n", err)
					return
				}

				if synced {
					break
				}

				time.Sleep(time.Second * 1)
			}

			_, bestHeight, err = activeChainControl.chainIO.GetBestBlock()
			if err != nil {
				return
			}

			ltndLog.Infof("Chain backend is fully synced (end_height=%v)!",
				bestHeight)
		}

		// With all the relevant chains initialized, we can finally start the
		// server itself.
		if err := server.Start(); err != nil {
			srvrLog.Errorf("unable to create to start server: %v\n", err)
			return
		}

		s.Serve(lis)
	}()


	//// Now that the server has started, if the autopilot mode is currently
	//// active, then we'll initialize a fresh instance of it and start it.
	//var pilot *autopilot.Agent
	//if cfg.Autopilot.Active {
	//	pilot, err := initAutoPilot(server, cfg.Autopilot)
	//	if err != nil {
	//		ltndLog.Errorf("unable to create autopilot agent: %v",
	//			err)
	//		return err
	//	}
	//	if err := pilot.Start(); err != nil {
	//		ltndLog.Errorf("unable to start autopilot agent: %v",
	//			err)
	//		return err
	//	}
	//}


	//if err := s.Serve(lis); err != nil {
	//	log.Fatalf("failed to serve: %v", err)
	//}

	return nil
}

func Stop() {
	chanDB.Close()
	//if chainCleanUp != nil {
	//	defer chainCleanUp()
	//}
	//defer lis.Close()
}

func newChainControlFromConfig2(chanDB *channeldb.DB, dataDir string) (*chainControl, func(), error) {
	privateWalletPw := []byte("hello")
	publicWalletPw := []byte("public")

	cc := &chainControl{}

	feeEstimator := lnwallet.StaticFeeEstimator{
		FeeRate: 50,
	}

	cc.feeEstimator = feeEstimator
	cc.routingPolicy = defaultBitcoinForwardingPolicy

	network := chaincfg.TestNet3Params

	walletConfig := &btcwallet.Config{
		PrivatePass:  privateWalletPw,
		PublicPass:   publicWalletPw,
		DataDir:      dataDir,
		NetParams:    &network,
		FeeEstimator: feeEstimator,
	}

	var (
		err     error
		cleanUp func()
	)

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

func InvokeMethod(methodName string, request []byte) ([]byte, error) {

	// TODO(simon): Implement.

	return nil, nil
}
