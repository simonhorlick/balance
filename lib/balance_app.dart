import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:balance/inprocess.dart';
import 'package:balance/receive.dart';
import 'package:balance/scan.dart';
import 'package:balance/topup.dart';
import 'package:balance/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:grpc/grpc.dart';

// This is the "normal" app flow, where we can assume the wallet has been
// and initialised is available for use.
class BalanceApp extends StatefulWidget {
  @override
  BalanceAppState createState() => new BalanceAppState();
}

class BalanceAppState extends State<BalanceApp> {
  bool loaded = false;
  LightningClient stub;

  bool useInproc = false;

  // Connect to an LND instance that's listening on a tcp socket. This is useful
  // for debugging.
  connectRemote() async {
    var cert = await readCertificate();
    ClientChannel channel = new ClientChannel('localhost',
        port: 10009,
        options: new ChannelOptions(
            credentials: new ChannelCredentials.secure(certificates: cert)));

    stub = new LightningClient(channel);

    setState(() {
      loaded = true;
    });
  }

  connect() async {
    stub = new LightningClient(new InProcChannel());

    setState(() {
      loaded = true;
    });
  }

  @override
  initState() {
    super.initState();

    if (useInproc) {
      start().then((msg) async {
        print("LndClient: start $msg");
        connect();
      });
    } else {
      connectRemote();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return new MaterialApp(
        title: 'Balance',
        theme: new ThemeData(primarySwatch: Colors.blue),
        home: new Center(
            child: new Text(
          "Connecting to LND",
          style: const TextStyle(color: Colors.white),
        )),
      );
    }

    return new MaterialApp(
      title: 'Balance',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new Wallet(stub),
      routes: <String, WidgetBuilder>{
        '/wallet': (BuildContext context) => new Wallet(stub),
        '/scan': (BuildContext context) => new Scanner(stub),
        '/topup': (BuildContext context) => new Topup(stub),
        '/receive': (BuildContext context) => new Receive(stub),
      },
    );
  }
}
