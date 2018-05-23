import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:balance/qr.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const kNormalText = const TextStyle(color: Colors.white, fontSize: 16.0);

/// Topup displays a QR code of a bitcoin address for depositing bitcoin from
/// an external source such as a wallet or exchange.
class Topup extends StatefulWidget {
  LightningClient stub;

  Topup(this.stub);

  @override
  _TopupState createState() => new _TopupState();
}

class _TopupState extends State<Topup> {
  // Whether the user has copied the address to the devices clipboard.
  bool isCopied = false;

  // The result of a call to newAddress.
  Future<NewAddressResponse> addressResponse;

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

    // Once the rpc has finished, show the QR code.
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
                    new GestureDetector(
                        onTap: () async {
                          const url =
                              'https://testnet.manu.backend.hamburg/faucet';
                          if (await canLaunch(url)) {
                            await launch(url, forceSafariVC: false);
                          } else {
                            throw 'Could not launch $url';
                          }
                        },
                        child: new Align(
                          alignment: Alignment.centerLeft,
                          child: new Text("Click here to go to the faucet.",
                              style: kNormalText),
                        ))
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
