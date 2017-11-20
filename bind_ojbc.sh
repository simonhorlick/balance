#!/bin/bash

pushd ios
  gomobile bind -target=ios github.com/simonhorlick/balance/lnd
popd
