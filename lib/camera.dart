import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

typedef void BarcodeCallback(String barcode);

class CameraApp extends StatefulWidget {
  final BarcodeCallback barcodeCallback;

  CameraApp(this.barcodeCallback);

  @override
  _CameraAppState createState() => new _CameraAppState(barcodeCallback);
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;
  String barcode;

  BarcodeCallback barcodeCallback;

  _CameraAppState(this.barcodeCallback);

  setupCamera() async {
    var cameras = await availableCameras();

    controller = new CameraController(cameras[0], ResolutionPreset.high);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });

    // Refresh this widget if anything changes.
    controller.addListener(() {
      if (barcode != controller.value.barcodeData) {
        print("New barcode: ${controller.value.barcodeData}");
        barcodeCallback(controller.value.barcodeData);
        setState(() {
          barcode = controller.value.barcodeData;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    setupCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return new Container();
    }
    return new Stack(children: [
      new AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: new CameraPreview(controller)),
      barcode == null ? new Container() : new Text(barcode),
    ]);
  }
}
