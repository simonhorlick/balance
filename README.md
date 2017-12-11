# balance

A modern cryptocurrency wallet.

## Goals

Every wallet app has a different reason for existence.
The following are a list of goals and non-goals of balance.

1. Have a very high-level interface that hides implementation details
1. Be rock solid and reliable
1. First-class support for lightning payments and requests
1. Focus on usability for merchants

### Non-goals

1. Have a large number of features
1. Support bitcoin transactions

## Getting Started

Note that there are a lot of moving parts here, and a few different languages.

Balance is built with [flutter](http://flutter.io/), a modern reactive mobile app SDK.
To begin, install the flutter SDK and follow the flutter getting started instructions.

Install the golang dependencies by running:
```bash
$ glide install
```

Ensure you have gomobile in your path:
```bash
$ go get golang.org/x/mobile/cmd/gomobile
$ gomobile init # it might take a few minutes
```

Ensure you have protoc, the protocol buffer compiler in your path:
```bash
$ brew install protobuf
```

Generate the client stubs for the app to communicate with LND:
```bash
$ ./generate_stubs.sh
```

Compile LND and generate the native bindings:
```bash
$ ./bind_objc.sh
```

Finally we can run the app:
```bash
$ flutter run
```