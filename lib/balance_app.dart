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
