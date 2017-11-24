import 'dart:async';

import 'package:balance/balance_app.dart';
import 'package:balance/daemon.dart';
import 'package:balance/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


// Each time we start the app, we first check to see if this is the first time
// the user has started the app. If so, we need to run the onboarding flow.
class FirstTimeRedirect extends StatelessWidget {

  final Future<bool> walletExists = Daemon.walletExists();

  @override
  Widget build(BuildContext context) {
    return new FutureBuilder<bool>(
      future: walletExists,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasError)
          return new Text('Error: ${snapshot.error}');
        else
          return snapshot.data ?
          new BalanceApp() :
          new MaterialApp(
            title: 'Balance',
            theme: new ThemeData(primarySwatch: Colors.blue),
            home: new HelloScreen(),
          );
      },
    );
  }
}
