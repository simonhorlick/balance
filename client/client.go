package client

import "github.com/simonhorlick/balance/lnd"

func Start(dataDir string) error {
	return lnd.Start(dataDir)
}

func Stop() {
	lnd.Stop()
}