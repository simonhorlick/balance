import 'dart:async';
import 'dart:convert';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

class Topup extends StatefulWidget {
  Topup(this.stub);

  final LightningClient stub;

  @override
  _TopupState createState() => new _TopupState();
}

class _TopupState extends State<Topup> {
  String address;

  Future refresh() async {
    var addressResponse = await widget.stub.newAddress(
        NewAddressRequest.create()
          ..type = NewAddressRequest_AddressType.NESTED_PUBKEY_HASH);

    setState(() {
      address = addressResponse.address;
    });

    return null;
  }

  @override
  initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (address == null) {
      return new Container();
    }

    return new TopupPage(address);
  }
}

class AddressBox extends StatelessWidget {
  AddressBox(this.address);

  final String address;

  @override
  Widget build(BuildContext context) {
    return new Expanded(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text("Your wallet address is:"),
          new TextField(
            controller: new TextEditingController(text: "$address"),
          ),
        ],
      ),
    );
  }
}

class TopupPage extends StatelessWidget {
  TopupPage(this.address);

  final String address;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Padding(
        padding: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: new Column(children: [
          new Align(alignment: Alignment.centerLeft, child: new BackButton()),
          new AddressBox(address),
        ]),
      ),
    );
  }
}
