#!/bin/bash

mkdir -p lnd

TO_COPY=( breacharbiter.go chainparams.go chainregistry.go config.go fundingmanager.go invoiceregistry.go log.go nodesigner.go peer.go rpcserver.go server.go signal.go utxonursery.go nursery_store.go version.go )

for i in "${TO_COPY[@]}"
do
  cp -v vendor/github.com/lightningnetwork/lnd/$i ./lnd/
done

gsed -i 's/package main/package lnd/g' lnd/*.go
