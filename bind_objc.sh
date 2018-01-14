#!/bin/bash

pushd ios
  gomobile bind -v -target=ios github.com/simonhorlick/balance/client
popd
