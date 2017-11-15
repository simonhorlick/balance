import 'package:flutter/material.dart';

import 'package:balance/welcome.dart';
import 'package:balance/transactions.dart';

void main() => runApp(new BalanceApp());

class BalanceApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Balance',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new Welcome(),
      routes: <String, WidgetBuilder>{
        '/welcome': (BuildContext context) => new Welcome(),
        '/transactions': (BuildContext context) => new Transactions(),
      },
    );
  }
}
