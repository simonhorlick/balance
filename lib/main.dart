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
    // Wait until we've loaded grpc before we attempt to draw anything else.
    // This should just take a couple of millis.
    if (_stub == null) {
      return new MaterialApp(
        title: 'Balance',
        theme: new ThemeData(primarySwatch: Colors.blue),
        home: new Center(child: new Text("Loading RPC")),
      );
    }

    return new MaterialApp(
      title: 'Balance',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new Tabs(_stub),
      routes: <String, WidgetBuilder>{
        '/welcome': (BuildContext context) => new Welcome(),
        '/tabs': (BuildContext context) => new Tabs(_stub),
        '/scan': (BuildContext context) => new Cam(),
      },
    );
  }
}
