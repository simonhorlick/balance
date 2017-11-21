import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class Wallet extends StatefulWidget {
  Wallet(this.stub);

  final LightningClient stub;

  @override
  _WalletState createState() => new _WalletState();
}

class _WalletState extends State<Wallet> {
  Int64 balance = new Int64(0);
  Int64 channelBalance = new Int64(0);
  String address;
  Timer balancePoller;

  var formatter = new NumberFormat("###,###", "en_US");

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
    }).catchError((error) => print("walletBalance failed: $error"));
    widget.stub
        .channelBalance(ChannelBalanceRequest.create())
        .then((response) {
      setState(() {
        channelBalance = response.balance;
      });
    }).catchError((error) => print("channelBalance failed: $error"));
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
    var totalBalance = balance + channelBalance;

    return new Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        new Text("${formatter.format(totalBalance)}", style: new TextStyle(fontSize: 26.0)),
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
