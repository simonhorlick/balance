import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

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
    return new Texture(textureId: cameraId.textureId);
  }
}

typedef Widget CameraWidgetBuilder(
    BuildContext context, Future<CameraId> cameraId);

class Cam extends StatefulWidget {
  Cam(this.stub);

  final LightningClient stub;

  @override
  CamState createState() {
    return new CamState();
  }
}

class CamState extends State<Cam> {
  bool opening = false;
  Camera camera;
  List<CameraDescription> cameras = new List();
  bool started;
  String filename;
  int pictureCount = 0;
  String barcode;

  bool seenBarcode = false;

  @override
  void initState() {
    super.initState();

    // Make the status bar white.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Query the list of available cameras and create a Camera Widget.
    availableCameras().then((List<CameraDescription> available) {
      this.cameras = available
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .toList();

      if (this.cameras.isNotEmpty) {
        CameraFormat previewFormat = this.cameras.first.previewFormats.first;
        CameraFormat captureFormat = this.cameras.first.captureFormats.first;

        this.cameras.first.open(previewFormat, captureFormat, (barcode) {
          if (seenBarcode) return;
          seenBarcode = true;

          SendRequest request = SendRequest.create()..paymentRequest = barcode;
          print("Calling sendPaymentSync");

          widget.stub.sendPaymentSync(request).then((response) {
            print("error is: ${response.paymentError}");
            print("rest is: $response");
            Navigator.pop(context, barcode);
          }).catchError((error) => print("failed to sendPaymentSync: $error"));

          setState(() {
            this.barcode = barcode;
          });
        }).then((cameraId) {
          setState(() {
            this.camera = new Camera(cameraId);
            started = true;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return new Stack(children: [
      // The camera sits at the bottom of the stack.
      (camera == null) ? new Text("") : camera,
      // Slightly darken the top of the screen, so the user can still read the
      // status bar.
      new Container(
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
                    new GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: new Padding(
                          padding: new EdgeInsets.all(16.0),
                          child: new Text("Back",
                              style: theme.textTheme.subhead
                                  .copyWith(color: Colors.white))),
                    ),
                    new GestureDetector(
                      onTap: _showInvoiceDialog,
                      child: new Padding(
                          padding: new EdgeInsets.all(16.0),
                          child: new Text("Paste Invoice",
                              style: theme.textTheme.subhead
                                  .copyWith(color: Colors.white))),
                    ),
                  ]))),
      // A rounded rectangular region for placing a QR code to scan.
      new Center(
          child: new FractionallySizedBox(
        widthFactor: 0.5,
        heightFactor: 0.33,
        child: new Container(
          decoration: new BoxDecoration(
            borderRadius: new BorderRadius.all(new Radius.circular(5.0)),
            border: new Border.all(width: 2.0, color: Colors.yellow),
          ),
          child: new SizedBox.fromSize(
            size: new Size.fromHeight(100.0),
          ),
        ),
      )),
      new Center(
        child: (barcode == null)
            ? new Text("")
            : new Text(barcode,
                style: new TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 11.0,
                    color: Colors.white)),
      ),
    ]);
  }

  void _showInvoiceDialog() {
    Navigator
        .push(
            context,
            new MaterialPageRoute<String>(
              builder: (BuildContext context) => new FullScreenInvoice(),
              fullscreenDialog: true,
            ))
        .then((invoice) {
      if (invoice != null) {
        // TODO(simon): Decode payment request here and display the details.
        _confirmAmountDialog().then((value) {
          if (value == DialogDemoAction.pay) {
            SendRequest request = SendRequest.create()
              ..paymentRequest = invoice;
            widget.stub.sendPaymentSync(request).then((response) {
              print(response);
              Navigator.pop(context, invoice);
            });
          }
        });
      }
    });
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
    return new Scaffold(
      appBar: new AppBar(title: const Text("Paste Invoice"), actions: <Widget>[
        new FlatButton(
            child: new Text('PAY'),
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
