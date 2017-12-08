import 'package:balance/channels.dart';
import 'package:balance/daemon.dart';
import 'package:balance/receive.dart';
import 'package:balance/topup.dart';
import 'package:balance/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:balance/scan.dart';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';

// This is the "normal" app flow, where we can assume LND is available.
class BalanceApp extends StatefulWidget {
  @override
  BalanceAppState createState() => new BalanceAppState();
}

class BalanceAppState extends State<BalanceApp> {
  LightningClient _stub;

  @override
  initState() {
    super.initState();
    Daemon.start("");
    _stub = Daemon.connect();

    // Add a well-known peer in case something goes wrong with bootstrapping.
    var addr = LightningAddress.create()
      ..host = "sg.horlick.me"
      ..pubkey =
          "038b869a90060ca856ac80ec54c20acebca93df1869fbee9550efeb238b964558c";

    _stub
        .connectPeer(ConnectPeerRequest.create()
          ..perm = true
          ..addr = addr)
        .then((response) {
      print("$response");
    }).catchError((error) {
      print("error: $error");
    });
  }

  @override
  dispose() {
    super.dispose();
    // TODO(simon): Close channel here?
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Balance',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new Wallet(_stub),
      routes: <String, WidgetBuilder>{
        '/wallet': (BuildContext context) => new Wallet(_stub),
        '/scan': (BuildContext context) => new Cam(_stub),
        '/topup': (BuildContext context) => new Topup(_stub),
        '/receive': (BuildContext context) => new Receive(_stub),
        '/channels': (BuildContext context) => new ChannelWrapper(_stub),
      },
    );
  }
}
