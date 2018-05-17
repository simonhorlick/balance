import 'package:balance/lnd.dart';
import 'package:balance/receive.dart';
import 'package:balance/scan.dart';
import 'package:balance/topup.dart';
import 'package:balance/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// This is the "normal" app flow, where we can assume the wallet has been
// and initialised is available for use.
class BalanceApp extends StatefulWidget {
  @override
  BalanceAppState createState() => new BalanceAppState();
}

class BalanceAppState extends State<BalanceApp> {
  bool loaded = false;

  @override
  initState() {
    super.initState();
    LndClient.start().then((msg) {
      print("LndClient: start $msg");
      setState(() {
        loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return new MaterialApp(
        title: 'Balance',
        theme: new ThemeData(primarySwatch: Colors.blue),
        home: new Text("Loading..."),
      );
    }

    return new MaterialApp(
      title: 'Balance',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new Wallet(),
      routes: <String, WidgetBuilder>{
        '/wallet': (BuildContext context) => new Wallet(),
        '/scan': (BuildContext context) => new Scanner(),
        '/topup': (BuildContext context) => new Topup(),
        '/receive': (BuildContext context) => new Receive(),
      },
    );
  }
}
