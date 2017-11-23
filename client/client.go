package client

import "github.com/simonhorlick/balance/lnd"

func Start(dataDir string) error {
	return lnd.Start(dataDir)
}

// On iOS the system may choose to reclaim resources while the app is
// suspended. In this case, the socket grpc uses for listening can be reclaimed
// causing the server to terminate. The simplest and most robust thing to do in
// this case is to destroy the grpc server when the app is backgrounded and
// re-create it again in Resume.
func Pause() {
	lnd.Pause()
}

func Resume() {
	lnd.Resume()
}

func Stop() {
	lnd.Stop()
}