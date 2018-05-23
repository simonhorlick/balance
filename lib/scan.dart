import 'dart:async';

import 'package:balance/camera.dart';
import 'package:balance/full_screen_invoice.dart';
import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// TODO(simon): Refactor this, it's used in a bunch of places.
var formatter = new NumberFormat("###,###", "en_US");

const kTitleText = const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold);
const kAmountText = const TextStyle(fontSize: 32.0);
const kDescriptionText = const TextStyle(fontSize: 16.0);
const kDestText =
    const TextStyle(fontSize: 10.0, color: const Color(0x80000000));

/// PaymentDetails displays the information contained within a payment request
/// to the user.
class PaymentDetails extends StatelessWidget {
  final Future<PayReq> details;

  PaymentDetails(this.details);

  @override
  Widget build(BuildContext context) {
    return new FutureBuilder<PayReq>(
      future: details,
      builder: (BuildContext context, AsyncSnapshot<PayReq> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return new Text('Decoding payment request');
          default:
            if (snapshot.hasError)
              return new Text('Error: ${snapshot.error}');
            else
              return new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    new Text('SENDING', style: kTitleText),
                    new SizedBox.fromSize(size: new Size.fromHeight(40.0)),
                    new Text('${formatter.format(snapshot.data.numSatoshis)}',
                        style: kAmountText),
                    new SizedBox.fromSize(size: new Size.fromHeight(20.0)),
                    new Text('${snapshot.data.description}',
                        textAlign: TextAlign.center, style: kDescriptionText),
                    new SizedBox.fromSize(size: new Size.fromHeight(20.0)),
                    new Text('destination: ${snapshot.data.destination}',
                        textAlign: TextAlign.center, style: kDestText),
                  ]);
        }
      },
    );
  }
}

/// A PaymentProgressScreen attempts to pay the given payment request
class PaymentProgressScreen extends StatefulWidget {
  final String paymentRequest;

  LightningClient stub;

  PaymentProgressScreen(this.paymentRequest, this.stub);

  @override
  _PaymentProgressScreenState createState() =>
      new _PaymentProgressScreenState();
}

class _PaymentProgressScreenState extends State<PaymentProgressScreen> {
  // The in-progress call to decodePayReq.
  Future<PayReq> details;

  // An error string to display to the user in case something goes wrong.
  String paymentError;

  @override
  initState() {
    super.initState();

    _sendPayment(widget.paymentRequest).then((paymentErrorResult) {
      if (paymentErrorResult == "") {
        // Success.
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          paymentError = paymentErrorResult;
        });
      }
    }).catchError((grpcError) {
      setState(() {
        paymentError = "${grpcError.message}";
      });
    });

    setState(() {
      details = widget.stub
          .decodePayReq(PayReqString.create()..payReq = widget.paymentRequest);
    });
  }

  Future<String> _sendPayment(String paymentRequest) async {
    var response = await widget.stub
        .sendPaymentSync(SendRequest.create()..paymentRequest = paymentRequest);

    return response.paymentError;
  }

  @override
  Widget build(BuildContext context) {
    var kTitleText = new TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);

    // Either show the payment details, or an error message.
    var mainText = paymentError == null
        ? new PaymentDetails(details)
        : new Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            new Text("Payment Failed", style: kTitleText),
            new SizedBox.fromSize(size: new Size.fromHeight(20.0)),
            new Text(paymentError),
          ]);

    return new Scaffold(
      body: new GestureDetector(
        onTap: _dismiss,
        child: new Padding(
          padding: new EdgeInsets.all(20.0),
          child: new Center(
            child: mainText,
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    // Only allow dismissing the screen if the payment failed.
    if (paymentError != null) {
      Navigator.of(context).pop(false);
    }
  }
}

/// The top navigation bar for the QR code scanner.
class TopBar extends StatelessWidget {
  final Function _showInvoiceDialog;

  TopBar(this._showInvoiceDialog);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    var textStyle = theme.textTheme.subhead.copyWith(color: Colors.white);

    // Slightly darken the top of the screen, so the user can still read the
    // status bar.
    return new Container(
        decoration: new BoxDecoration(
          gradient: new LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xA0000000), const Color(0x00000000)],
          ),
        ),
        child: new SizedBox.fromSize(
            size: new Size.fromHeight(100.0),
            child: new Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  new BackButton(color: Colors.white),
                  new GestureDetector(
                    onTap: _showInvoiceDialog,
                    child: new Padding(
                        padding: new EdgeInsets.all(16.0),
                        child: new Text("Paste Invoice", style: textStyle)),
                  ),
                ])));
  }
}

/// A rounded rectangular region for placing a QR code to scan.
class GuideOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Center(
        child: new FractionallySizedBox(
      widthFactor: 0.5,
      heightFactor: 0.33,
      child: new Container(
        decoration: new BoxDecoration(
          borderRadius: new BorderRadius.all(new Radius.circular(5.0)),
          border: new Border.all(width: 2.0, color: Colors.blue),
        ),
        child: new SizedBox.fromSize(
          size: new Size.fromHeight(100.0),
        ),
      ),
    ));
  }
}

/// The main QR-code scanner screen. A Scanner attempts to start the
/// back-facing camera and listens for QR codes. If a QR code is seen, we pass
/// it straight to the PaymentProgressScreen which attempts to pay the payment
/// request.
class Scanner extends StatefulWidget {
  final LightningClient stub;

  Scanner(this.stub);

  @override
  _ScannerState createState() {
    return new _ScannerState();
  }
}

class _ScannerState extends State<Scanner> {
  CameraApp camera;

  bool seenBarcode = false;

  // Starts the progress screen. This initiates the actual payment and displays
  // updates on its progress.
  Future<Null> _showProgressScreen(String paymentRequest) async {
    // We use pushReplacement here because the camera doesn't currently start
    // back up properly when we navigate back.
    Navigator.of(context).pushReplacement(new MaterialPageRoute<bool>(
          builder: (BuildContext context) =>
              new PaymentProgressScreen(paymentRequest, widget.stub),
          fullscreenDialog: true,
        ));
  }

  void _barcodeScanned(String barcode) {
    // Only use the first occurrence of a barcode.
    if (seenBarcode) {
      return;
    } else {
      seenBarcode = true;
    }

    if (barcode.startsWith("lightning:")) {
      barcode = barcode.substring("lightning:".length);
    }
    if (barcode.startsWith("//")) {
      barcode = barcode.substring("//".length);
    }

    _showProgressScreen(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Stack(children: [
        // The camera sits at the bottom of the stack.
        new CameraApp(_barcodeScanned),
        new TopBar(_showInvoiceDialog),
        new GuideOverlay(),
        new Center(
            child: new FlatButton(
          child: new Text("Click Me!"),
          onPressed: () {
            _barcodeScanned(
                "lightning:lntb100u1pds2tg3pp5eeqhhk4vtfh523exfqvh26n0nqh29ztvf9vdzl9y5eaghgytetxsdqqcqzysxqyz5vq47zjmr2th2hvcf858lz0l6fhaufvhscda6lqcge0hjyd960vzva43amunya9zk7ayx08kr7h0m5pr70axjudfk2yfe57sc54wxvdkksptgpsrj");
          },
        ))
      ]),
    );
  }

  Future<Null> _showInvoiceDialog() async {
    var invoice =
        await Navigator.of(context).push(new MaterialPageRoute<String>(
              builder: (BuildContext context) => new FullScreenInvoice(),
              fullscreenDialog: true,
            ));
    if (invoice != null) {
      _showProgressScreen(invoice);
    }
  }
}
