import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

enum DialogDemoAction {
  cancel,
  pay,
}

class Camera extends StatefulWidget {
  final CameraId cameraId;

  Camera(this.cameraId);

  @override
  State createState() {
    return new _CameraState(cameraId);
  }
}

class _CameraState extends State<StatefulWidget> {
  final CameraId cameraId;
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

class PaymentProgressScreen extends StatefulWidget {
  final String paymentRequest;
  final LightningClient stub;

  PaymentProgressScreen(this.paymentRequest, this.stub);

  @override
  _PaymentProgressScreenState createState() =>
      new _PaymentProgressScreenState();
}

class _PaymentProgressScreenState extends State<PaymentProgressScreen> {
  String paymentError;

  @override
  initState() {
    super.initState();

    _sendPayment(widget.paymentRequest).then((paymentErrorResult) {
      if (paymentErrorResult == "") {
        // Success.
        Navigator.of(context).pop();
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
  }

  Future<String> _sendPayment(String paymentRequest) async {
    var response = await widget.stub
        .sendPaymentSync(SendRequest.create()..paymentRequest = paymentRequest);

    return response.paymentError;
  }

  @override
  Widget build(BuildContext context) {
    var kTitleText = new TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);

    var mainText = paymentError == null
        ? new Text("Sending payment...") // TODO(simon): show payment details here
        : new Column(
      mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
    Navigator.of(context).pop();
  }
}

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

class Cam extends StatefulWidget {
  Cam(this.stub);

  final LightningClient stub;

  @override
  CamState createState() {
    return new CamState();
  }
}

class CamState extends State<Cam> {
  Camera camera;
  List<CameraDescription> cameras = new List();

  bool seenBarcode = false;

  // Starts the progress screen. This initiates the actual payment and displays
  // updates on its progress.
  Future<Null> _showProgressScreen(String paymentRequest) async {
    Navigator.of(context).push(new MaterialPageRoute<String>(
          builder: (BuildContext context) =>
              new PaymentProgressScreen(paymentRequest, widget.stub),
          fullscreenDialog: true,
        ));
  }

  void _confirmAndPay(String paymentRequest) {
    _confirmAmountDialog().then((action) {
      if (action == DialogDemoAction.pay) {
        _showProgressScreen(paymentRequest);
      } else if (action == DialogDemoAction.cancel) {
        // Reset the barcode scanner so we can continue scanning.
        setState(() {
          seenBarcode = false;
        });
      }
    });
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

    _confirmAndPay(barcode);
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
    var invoice = await Navigator.of(context).push(
            new MaterialPageRoute<String>(
              builder: (BuildContext context) => new FullScreenInvoice(),
              fullscreenDialog: true,
            ));
    if (invoice != null) {
      _confirmAndPay(invoice);
    }
  }

  Future<DialogDemoAction> _confirmAmountDialog() {
    return showDialog(
      context: context,
      child: new AlertDialog(
          content: new Text(
            "Are you sure?",
          ),
          actions: <Widget>[
            new FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context, DialogDemoAction.cancel);
                }),
            new FlatButton(
                child: const Text('PAY'),
                onPressed: () {
                  Navigator.pop(context, DialogDemoAction.pay);
                })
          ]),
    );
  }
}

class FullScreenInvoice extends StatefulWidget {
  @override
  FullScreenInvoiceState createState() => new FullScreenInvoiceState();
}

class FullScreenInvoiceState extends State<FullScreenInvoice> {
  String invoice;
  @override
  Widget build(BuildContext context) {
    var textStyle = Theme.of(context).textTheme.subhead.copyWith(color: Colors.white);

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
          new TextField(
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
          )
        ],
      )),
    );
  }

  String _validateInvoice(String value) {
    // TODO(simon): Implement.
    return null;
  }
}
