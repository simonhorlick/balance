import 'dart:async';
import 'dart:convert';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

class Wallet extends StatefulWidget {
  Wallet(this.stub);

  final LightningClient stub;

  @override
  _WalletState createState() => new _WalletState();
}

class _WalletState extends State<Wallet> {
  Int64 balance = new Int64(0);
  Int64 channelBalance = new Int64(0);
  Int64 pendingChannelBalance = new Int64(0);
  Int64 limboBalance = new Int64(0);

  double converted = 0.0;

  String address;
  Timer balancePoller;

  var formatter = new NumberFormat("###,###", "en_US");
  var fiatFormatter = new NumberFormat("###,###.00", "en_US");

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

  _getCurrentRate(sat) async {
    String url = "http://sg.horlick.me:8000/rates/XBTMYR2?sat=$sat";
    var httpClient = createHttpClient();
    var response = await httpClient.read(url);
    Map data = JSON.decode(response);
    double fiat = data['cumulativeFiat'];

    if (!mounted) return;

    setState(() {
      converted = fiat;
    });
  }

  void refreshBalance() {
    // Take the on-chain available balance.
    widget.stub
        .walletBalance(WalletBalanceRequest.create()..witnessOnly = true)
        .then((response) {
      setState(() {
        balance = response.balance;
      });
      // Call out to FX service.
      _getCurrentRate(balance);
    }).catchError((error) => print("walletBalance failed: $error"));

//    widget.stub
//        .getTransactions(GetTransactionsRequest.create())
//        .then((response) {
//      response.transactions.forEach((tx) => print("tx: ${tx.amount}"));
//    }).catchError((error) => print("getTransactions failed: $error"));

    // The sum of everything we have in an active channel.
    widget.stub.channelBalance(ChannelBalanceRequest.create()).then((response) {
      setState(() {
        channelBalance = response.balance;
      });
    }).catchError((error) => print("channelBalance failed: $error"));

    // And sum everything we're trying to assign to new channels that are still
    // pending.
    widget.stub
        .pendingChannels(PendingChannelRequest.create())
        .then((response) {
      setState(() {
        pendingChannelBalance = response.pendingOpenChannels
            .map((chan) => chan.channel.localBalance)
            .reduce((value, element) => value + element);
        limboBalance = response.totalLimboBalance;
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
    var totalBalance =
        balance + channelBalance + pendingChannelBalance + limboBalance;

    return new Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        new Column(
          children: <Widget>[
            new Text("${formatter.format(totalBalance)}",
                style: new TextStyle(fontSize: 26.0)),
            converted > 0.0
                ? new Text("RM ${fiatFormatter.format(converted)}")
                : new Text("...", style: const TextStyle(color: const Color(0x00FFFFFF))),
          ],
        ),
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
