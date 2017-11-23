package client

import (
	"github.com/simonhorlick/balance/lnd"
	"sync"
	"log"
)

func Start(dataDir string) error {
	return lnd.Start(dataDir)
}

// The mutex guards the Pause and Resume functionality, ensuring that calls
// to Pause and Resume are serialised and that duplicate calls are handled
// correctly.
var mutex = &sync.Mutex{}

// Guarded by mutex.
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

	if running {
		log.Print("Lnd already running")
		return
	}
	running = true

	lnd.Resume()
}

func Stop() {
	lnd.Stop()
}