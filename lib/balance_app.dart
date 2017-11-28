import 'package:balance/daemon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:balance/scan.dart';
import 'package:balance/tabs.dart';
import 'package:balance/welcome.dart';

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
      ..pubkey = "0294ceb8edf4b54da71caa506723dc8ab9c129ae19da4267f0e6d7cdcb396615b0";

    _stub.connectPeer(ConnectPeerRequest.create()
      ..perm = true
      ..addr = addr).then((response) {
      print("$response");
    })
    .catchError((error) {
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
      home: new Tabs(_stub),
      routes: <String, WidgetBuilder>{
        '/welcome': (BuildContext context) => new Welcome(),
        '/tabs': (BuildContext context) => new Tabs(_stub),
        '/scan': (BuildContext context) => new Cam(_stub),
      },
    );
  }
}
