import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();

    // Make the status bar white.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Query the list of available cameras and create a Camera Widget.
    availableCameras().then((List<CameraDescription> available) {
      setState(() async {
        this.cameras = available
            .where((camera) => camera.lensDirection == CameraLensDirection.back)
            .toList();

        if (this.cameras.isNotEmpty) {
          CameraFormat previewFormat = this.cameras.first.previewFormats.first;
          CameraFormat captureFormat = this.cameras.first.captureFormats.first;

          var cameraId = await this.cameras.first.open(
              previewFormat,
              captureFormat,
                  (barcode) => setState(() {
                this.barcode = barcode;
              }));
          setState(() {});
          this.camera = new Camera(cameraId);
          started = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
          )),
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
}