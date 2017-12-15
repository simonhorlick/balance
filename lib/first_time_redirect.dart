import 'dart:async';

import 'package:balance/balance_app.dart';
import 'package:balance/daemon.dart';
import 'package:balance/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// Each time we start the app, we first check to see if this is the first time
// the user has started the app. If so, we need to run the onboarding flow.

class FirstTimeRedirect extends StatefulWidget {
  @override
  _FirstTimeRedirectState createState() => new _FirstTimeRedirectState();
}

class _FirstTimeRedirectState extends State<FirstTimeRedirect> {
  bool walletExists;
  bool ready = false;

  @override
  void initState() {
    super.initState();

    Daemon.walletExists().then((exists) {
      if (exists) {
        print("FirstTimeRedirect: Wallet exists, starting lnd");

        // Start LND and start listening for rpcs.
        Daemon.start("");
      } else {
        print("FirstTimeRedirect: Wallet doesn't exist, showing onboarding");
      }

      setState(() {
        ready = true;
        walletExists = exists;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return new Container();
    }

    return walletExists
        ? new BalanceApp()
        : new MaterialApp(
            title: 'Balance',
            theme: new ThemeData(primarySwatch: Colors.blue),
            home: new HelloScreen(),
          );
  }
}
