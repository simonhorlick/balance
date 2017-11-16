#!/bin/bash

# Assumes you have installed protoc_plugin globally, i.e.
#  pub global activate protoc_plugin
#  PATH=$PATH:$HOME/.pub-cache/bin

mkdir -p gen

# Assumes you have dart installed, i.e.
#  brew tap dart-lang/dart
#  brew install dart
protoc \
  -I. \
  -Ithird_party/googleapis \
  --dart_out=gen \
  rpc.proto
