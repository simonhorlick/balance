#!/bin/bash

# Assumes you have installed protoc_plugin globally and that you have dart
# installed, i.e.
#  brew tap dart-lang/dart
#  brew install dart --devel
#  pub global activate protoc_plugin
#  PATH=$PATH:$HOME/.pub-cache/bin

mkdir -p lib/generated

protoc \
  -I. \
  -Ithird_party/googleapis \
  --plugin=$HOME/.pub-cache/bin/protoc-gen-dart \
  --dart_out=grpc:lib/generated \
  vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.proto
