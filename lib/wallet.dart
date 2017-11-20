import 'dart:async';

import 'package:balance/generated/rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

class Wallet extends StatefulWidget {
  Wallet(this.stub);

  final LightningClient stub;

  @override
  _WalletState createState() => new _WalletState();
}

class _WalletState extends State<Wallet> {
  Int64 balance;
  String address;
  Timer balancePoller;

  @override
  initState() {
    super.initState();
    createAddress();
    refreshBalance();

    // Set up a timer that polls the wallet balance each second.
    balancePoller = new Timer.periodic(new Duration(seconds: 1), (timer) {
      refreshBalance();
    });
  }

  @override
  void deactivate() {
    balancePoller.cancel();
    super.deactivate();
  }

  void refreshBalance() {
    widget.stub
        .walletBalance(WalletBalanceRequest.create()..witnessOnly = true)
        .then((response) {
      setState(() {
        balance = response.balance;
      });
    }).catchError((error) => print("walletBalance failed"));
  }

  void createAddress() {
    NewAddressRequest request = NewAddressRequest.create()
      ..type = NewAddressRequest_AddressType.NESTED_PUBKEY_HASH;
    widget.stub.newAddress(request).then((response) {
      address = response.address;
    }).catchError((error) => print("newAddress failed"));
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        new Text("$balance", style: new TextStyle(fontSize: 26.0)),
        new Column(
          children: <Widget>[
            new Text("Your wallet address is:"),
            new TextField(
              controller: new TextEditingController(text: "$address"),
            ),
          ],
        ),
      ],
    );
  }
}
