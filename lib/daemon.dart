import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';

const MethodChannel _kChannel = const MethodChannel('wallet_init_channel');

class Daemon {

  // Checks whether a wallet has been created.
  static Future<bool> walletExists() async {
    return await _kChannel.invokeMethod('walletExists');
  }

  // Creates a new wallet and returns the 12-word BIP39 mnemonic for the seed.
  static Future<List<String>> createMnemonic() async {
    String mnemonic = await _kChannel.invokeMethod('createMnemonic');

    if (mnemonic.isEmpty) {
      return new Future.error("Failed to create mnemonic");
    }

    return mnemonic.split(" ");
  }

  // Initialises the wallet and uses the given mnemonic as the HD seed.
  static Future<Null> start(String mnemonic) async {
    return await _kChannel.invokeMethod('start', mnemonic);
  }

  static LightningClient connect() {
    ClientChannel channel = new ClientChannel('localhost',
        port: 10009,
        options: new ChannelOptions.insecure(
            idleTimeout: const Duration(seconds: 15)));
    return new LightningClient(channel,
        options: new CallOptions(
            timeout:
            new Duration(seconds: 15))); // some calls take a long time.
  }

}
