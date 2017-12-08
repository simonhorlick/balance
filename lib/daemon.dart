import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:grpc/grpc.dart';

const MethodChannel _kChannel = const MethodChannel('wallet_init_channel');


/// A mixin that begins polling LND when the widget is initialised, pauses when
/// the application is backgrounded, and resumes when the application is back
/// again.
abstract class DaemonPoller<T extends StatefulWidget> extends State<T> {

  Timer timer;

  @override
  initState() {
    super.initState();
    print("DaemonPoller: registering lifecycle callbacks");
    Daemon.registerListener(_pause, _resume);
  }

  void _resume() {
    print("DaemonPoller: application resumed, starting timer");
    timer = new Timer.periodic(new Duration(seconds: 5), (timer) {
      _refresh();
    });
    _refresh();
  }

  void _pause() {
    print("DaemonPoller: application paused, cancelling timer");
    timer.cancel();
  }

  @override
  dispose() {
    print("DaemonPoller: widget is being disposed, cancelling timer");
    Daemon.removeListener();
    timer.cancel();
    super.dispose();
  }

  Future<Null> _refresh();

}

class Daemon {

  /// Register for app lifecycle events and immediately dispatch a resume
  /// callback.
  static registerListener(void pause(), void resume()) {
    _kChannel.setMethodCallHandler((call) {
      if (call.method == "resume") {
        resume();
      } else if (call.method == "pause") {
        pause();
      }
    });
    resume();
  }

  static removeListener() {
    _kChannel.setMethodCallHandler(null);
  }

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
