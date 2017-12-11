import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:balance/daemon.dart';
import 'package:balance/receive.dart';
import 'package:balance/topup.dart';
import 'package:balance/wallet.dart';
import 'package:balance/scan.dart';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';

// This is the "normal" app flow, where we can assume the wallet has been
// and initialised is available for use.
class BalanceApp extends StatefulWidget {
  @override
  BalanceAppState createState() => new BalanceAppState();
}

class BalanceAppState extends State<BalanceApp> {
  // The client stub for communicating with LND.
  LightningClient _stub;

  @override
  initState() {
    super.initState();

    // Start LND and start listening for rpcs.
    Daemon.start("");

    // Create an rpc client.
    _stub = Daemon.connect();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Balance',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new Wallet(_stub),
      routes: <String, WidgetBuilder>{
        '/wallet': (BuildContext context) => new Wallet(_stub),
        '/scan': (BuildContext context) => new Scanner(_stub),
        '/topup': (BuildContext context) => new Topup(_stub),
        '/receive': (BuildContext context) => new Receive(_stub),
      },
    );
  }
}
