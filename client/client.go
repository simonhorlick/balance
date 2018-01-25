package client

import (
	"github.com/simonhorlick/balance/lnd"
	"sync"
	"log"
	b39 "github.com/tyler-smith/go-bip39"
	"github.com/roasbeef/btcutil/hdkeychain"
	"time"
)

// Start is called once when the application first starts.
func Start(dataDir string, mnemonic string) error {
	mutex.Lock()

	if started {
		log.Print("LND already started")
		mutex.Unlock()
		return nil
	}

	started = true
	mutex.Unlock()

	var seed []byte = nil
	var err error

	if mnemonic != "" {
		seed, err = b39.NewSeedWithErrorChecking(mnemonic, "")
		if err != nil {
			return err
		}
	}

	err = lnd.Start(dataDir, seed)
	if err != nil {
		log.Printf("lnd.Start failed: %v\n", err)
		return err
	}

	// Start the grpc layer.
	Resume()

	return nil
}

// The mutex guards the Pause and Resume functionality, ensuring that calls
// to Pause and Resume are serialised and that duplicate calls are handled
// correctly.
var mutex = &sync.Mutex{}

// Guarded by mutex.
var started = false
var running = false

// On iOS the system may choose to reclaim resources while the app is
// suspended. In this case, the socket grpc uses for listening can be reclaimed
// causing the server to terminate. The simplest and most robust thing to do in
// this case is to destroy the grpc server when the app is backgrounded and
// re-create it again in Resume.
func Pause() {
	mutex.Lock()
	defer mutex.Unlock()

	if !running {
		log.Print("Lnd already paused")
		return
	}
	running = false

	lnd.Pause()
}

func Resume() {
	mutex.Lock()
	defer mutex.Unlock()

	if !started {
		log.Print("Lnd not yet started")
		return
	}

	if running {
		log.Print("Lnd already running")
		return
	}
	running = true

	lnd.Resume()

	// This is a nasty hack to wait until the grpc server has started listening.
	time.Sleep(100 * time.Millisecond)
}

func WalletExists(dataDir string) bool {
	return lnd.WalletExists(dataDir)
}

func CreateBip39Seed() (string, error) {
	// Using 32 bytes of entropy gives us a 24 word seed phrase. Here we use
	// half of that to obtain a 12 word phrase.
	entropy, err := hdkeychain.GenerateSeed(16)
	if err != nil {
		return "", err
	}

	mnemonic, err := b39.NewMnemonic(entropy)
	if err != nil {
		return "", err
	}

	return mnemonic, nil
}

func Stop() {
	mutex.Lock()
	defer mutex.Unlock()

	if started {
		lnd.Stop()
	}
}