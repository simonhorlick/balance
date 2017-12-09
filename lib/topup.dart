import 'dart:async';
import 'dart:convert';

import 'package:balance/fit_width.dart';
import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:balance/qr.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

const kNormalText = const TextStyle(color: Colors.white, fontSize: 16.0);

class Topup extends StatelessWidget {
  final LightningClient stub;

  Topup(this.stub);

  @override
  Widget build(BuildContext context) {
    var addressBuilder = new FutureBuilder<NewAddressResponse>(
      future: stub.newAddress(NewAddressRequest.create()
        ..type = NewAddressRequest_AddressType.NESTED_PUBKEY_HASH),
      builder:
          (BuildContext context, AsyncSnapshot<NewAddressResponse> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return new Center(
                child: new Text('Generating address...', style: kNormalText));
          default:
            if (snapshot.hasError)
              return new Center(
                  child:
                      new Text('Error: ${snapshot.error}', style: kNormalText));
            else
              return new Padding(
                padding: new EdgeInsets.all(20.0),
                child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      new FitWidth(
                          child: new QrCodeWidget(
                              data: snapshot.data.address,
                              color: Colors.white)),
                      new Padding(
                          padding: new EdgeInsets.only(top: 20.0),
                          child: new Text(
                              "You can long press on the QR code to copy it.",
                              style: kNormalText)),
                    ]),
              );
        }
      },
    );

    return new Scaffold(
      backgroundColor: Colors.blue,
      body: new Padding(
        padding: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: new Column(children: [
          new Align(
              alignment: Alignment.centerLeft,
              child: new BackButton(color: Colors.white)),
          new Expanded(child: addressBuilder),
        ]),
      ),
    );
  }
}
