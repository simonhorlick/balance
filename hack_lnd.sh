#!/bin/bash

mkdir -p lnd

TO_COPY=( breacharbiter.go chainparams.go chainregistry.go config.go fundingmanager.go invoiceregistry.go log.go nodesigner.go peer.go rpcserver.go server.go signal.go utxonursery.go version.go )

for i in "${TO_COPY[@]}"
do
  cp -v vendor/github.com/lightningnetwork/lnd/$i ./lnd/
done

gsed -i 's/package main/package lnd/g' lnd/*.go

# Don't attempt to export CsvSpendableOutput because it uses uint32 which
# gobind doesn't like.
gsed -i 's/CsvSpendableOutput/csvSpendableOutput/g' lnd/utxonursery.go

