import 'dart:async';
import 'dart:convert';

import 'package:balance/fit_width.dart';
import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:balance/qr.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:grpc/src/shared.dart';

import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

const kNormalText = const TextStyle(color: Colors.white, fontSize: 16.0);

class Topup extends StatefulWidget {
  final LightningClient stub;

  Topup(this.stub);

  @override
  _TopupState createState() => new _TopupState();
}

class _TopupState extends State<Topup> {
  bool isCopied = false;

  ResponseFuture<NewAddressResponse> addressResponse;

  @override
  initState() {
    super.initState();
    addressResponse = widget.stub.newAddress(NewAddressRequest.create()
      ..type = NewAddressRequest_AddressType.NESTED_PUBKEY_HASH);
  }

  @override
  Widget build(BuildContext context) {
    var copyText = isCopied
        ? new Text("Copied to clipboard.", style: kNormalText)
        : new Text("You can long press on the QR code to copy it.",
            style: kNormalText);

    var addressBuilder = new FutureBuilder<NewAddressResponse>(
      future: addressResponse,
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
              return new Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    new Expanded(
                        child: new AspectRatio(
                            aspectRatio: 1.0,
                            child: new QrCodeWidget(
                              data: snapshot.data.address,
                              color: Colors.white,
                              onCopied: () => setState(() {
                                    isCopied = true;
                                  }),
                            ))),
                    new Padding(
                        padding: new EdgeInsets.only(top: 20.0),
                        child: new SizedBox.fromSize(
                            size: new Size.fromHeight(50.0), child: copyText)),
                  ]);
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
          new Expanded(
              child: new Padding(
                  padding: new EdgeInsets.all(20.0), child: addressBuilder)),
        ]),
      ),
    );
  }
}
