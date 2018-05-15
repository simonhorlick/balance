import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:balance/lnd.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A camera preview widget.
class Camera extends StatefulWidget {
  final CameraId cameraId;

  Camera(this.cameraId);

  @override
  State createState() {
    return new _CameraState(cameraId);
  }
}

class _CameraState extends State<StatefulWidget> {
  // A reference to the camera that's being displayed.
  final CameraId cameraId;

  // Whether the camera is currently showing or not.
  bool isPlaying = true;

  _CameraState(this.cameraId);

  @override
  void initState() {
    super.initState();
    if (isPlaying) cameraId.start();
  }

  @override
  void deactivate() {
    if (isPlaying) cameraId.stop();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
        color: Colors.black, child: new Texture(textureId: cameraId.textureId));
  }
}

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

  PaymentProgressScreen(this.paymentRequest);

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
      details = LndClient
          .decodePayReq(PayReqString.create()..payReq = widget.paymentRequest);
    });
  }

  Future<String> _sendPayment(String paymentRequest) async {
    var response = await LndClient
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
  @override
  _ScannerState createState() {
    return new _ScannerState();
  }
}

class _ScannerState extends State<Scanner> {
  Camera camera;
  List<CameraDescription> cameras = new List();

  bool seenBarcode = false;

  // Starts the progress screen. This initiates the actual payment and displays
  // updates on its progress.
  Future<Null> _showProgressScreen(String paymentRequest) async {
    // We use pushReplacement here because the camera doesn't currently start
    // back up properly when we navigate back.
    Navigator.of(context).pushReplacement(new MaterialPageRoute<bool>(
          builder: (BuildContext context) =>
              new PaymentProgressScreen(paymentRequest),
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
  void initState() {
    super.initState();

    // Query the list of available cameras and create a Camera Widget.
    availableCameras().then((List<CameraDescription> available) {
      this.cameras = available
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .toList();

      if (this.cameras.isNotEmpty) {
        CameraFormat previewFormat = this.cameras.first.previewFormats.first;
        CameraFormat captureFormat = this.cameras.first.captureFormats.first;

        this
            .cameras
            .first
            .open(previewFormat, captureFormat, _barcodeScanned)
            .then((cameraId) {
          setState(() {
            this.camera = new Camera(cameraId);
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Stack(children: [
        // The camera sits at the bottom of the stack.
        (camera == null) ? new Container() : camera,
        new TopBar(_showInvoiceDialog),
        new GuideOverlay(),
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

/// A FullScreenInvoice allows the user to paste an invoice string for the case
/// where scanning a QR code is not practical.
class FullScreenInvoice extends StatefulWidget {
  @override
  FullScreenInvoiceState createState() => new FullScreenInvoiceState();
}

class FullScreenInvoiceState extends State<FullScreenInvoice> {
  String invoice;
  @override
  Widget build(BuildContext context) {
    var textStyle =
        Theme.of(context).textTheme.subhead.copyWith(color: Colors.white);

    return new Scaffold(
      appBar: new AppBar(title: const Text("Paste Invoice"), actions: <Widget>[
        new FlatButton(
            child: new Text('PAY', style: textStyle),
            onPressed: () {
              Navigator.pop(context, invoice);
            })
      ]),
      body: new Form(
          child: new ListView(
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.all(10.0),
            child: new TextField(
              decoration: const InputDecoration(
                hintText:
                    'For example, lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpuaztrnwngzn3kdzw5hydlzf03qdgm2hdq27cqv3agm2awhz5se903vruatfhq77w3ls4evs3ch9zw97j25emudupq63nyw24cg27h2rspfj9srp',
                labelText: 'Invoice Text',
              ),
              onChanged: (value) {
                setState(() {
                  invoice = value;
                });
              },
              maxLines: 3,
            ),
          )
        ],
      )),
    );
  }
}
