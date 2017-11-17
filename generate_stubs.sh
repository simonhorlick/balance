#!/bin/bash

# Assumes you have installed protoc_plugin globally, i.e.
#  pub global activate protoc_plugin
#  PATH=$PATH:$HOME/.pub-cache/bin

mkdir -p lib/generated

# Assumes you have dart installed, i.e.
#  brew tap dart-lang/dart
#  brew install dart
protoc \
  -I. \
  -Ithird_party/googleapis \
  --dart_out=grpc:lib/generated \
  rpc.proto
