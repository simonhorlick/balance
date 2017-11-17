import 'dart:async';
import 'package:balance/channels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:grpc/grpc.dart';
import 'package:balance/scan.dart';
import 'package:balance/tabs.dart';
import 'package:balance/welcome.dart';
import 'package:balance/generated/rpc.pbgrpc.dart';

void main() => runApp(new BalanceApp());

class BalanceApp extends StatefulWidget {
  @override
  BalanceAppState createState() => new BalanceAppState();
}

class BalanceAppState extends State<BalanceApp> {
  ClientChannel channel;
  LightningClient _stub;

  Future<List<int>> readCertificate() {
    return rootBundle.load('assets/tls.cert').then((cert) {
      List<int> intCert = new List();
      for (int i = 0; i < cert.lengthInBytes; i++) {
        intCert.add(cert.getUint8(i));
      }
      return intCert;
    });
  }

  Future<Null> connect() async {
    var cert = await readCertificate();
    channel = new ClientChannel('localhost',
        port: 10009, options: new ChannelOptions.secure(certificate: cert));
    var stub = new LightningClient(channel,
        options: new CallOptions(timeout: new Duration(seconds: 3)));
    setState(() {
      this._stub = stub;
    });
  }

  @override
  initState() {
    super.initState();
    connect();
  }

  @override
  dispose() {
    super.dispose();
    if (channel != null) {
      channel.shutdown();
    }
  }

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
      home: new Scaffold(body: new StubWrapper(stub: _stub)),
      routes: <String, WidgetBuilder>{
        '/welcome': (BuildContext context) => new Welcome(),
        '/tabs': (BuildContext context) => new Tabs(),
        '/scan': (BuildContext context) => new Cam(),
      },
    );
  }
}
