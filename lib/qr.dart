import 'package:balance/fit_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

import 'package:flutter/services.dart';

class QrContainer extends StatefulWidget {
  final String address;
  final TextStyle textStyle;
  final Color qrColor;

  QrContainer(this.address, this.textStyle, this.qrColor);

  @override
  _QrContainerState createState() => new _QrContainerState();
}

class _QrContainerState extends State<QrContainer> {
  bool isCopied = false;

  @override
  Widget build(BuildContext context) {
    var copyText = isCopied
        ? new Text("Copied to clipboard.", style: widget.textStyle)
        : new Text("You can long press on the QR code to copy it.",
            style: widget.textStyle);

    return new Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      new Padding(
        padding: new EdgeInsets.only(bottom: 20.0),
        child: new Text(
            "Send funds to the following address to begin using your wallet.\n\n"
            "This should take a few minutes, but could take up to an hour.",
            style: widget.textStyle),
      ),
      new Expanded(
          child: new AspectRatio(
              aspectRatio: 1.0,
              child: new QrCodeWidget(
                data: widget.address,
                color: Colors.black,
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
}

typedef void OnCopiedCallback();

class QrCodeWidget extends StatelessWidget {
  final String data;
  final Color color;
  final OnCopiedCallback onCopied;

  QrCodeWidget({this.data, this.color, this.onCopied});

  @override
  Widget build(BuildContext context) {
    // According to the table on http://www.qrcode.com/en/about/version.html
    // it's possible to store the following:
    //  typeNumber size
    //           5  154
    //           6  195
    //           7  224
    //           8  279
    //           9  335
    //          10  395

    var code = new QrCode(9, QrErrorCorrectLevel.L);
    code.addData(data);
    code.make();

    return new GestureDetector(
      onLongPress: () {
        Clipboard.setData(new ClipboardData(text: data));
        if (onCopied != null) {
          onCopied();
        }
        print("Copied the following to the clipboard: $data");
      },
      child: new CustomPaint(
        painter: new QrCodePainter(code, color),
      ),
    );
  }
}

class QrCodePainter extends CustomPainter {
  final QrCode code;
  final Color color;

  QrCodePainter(this.code, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var moduleWidth = size.width / code.moduleCount;
    var moduleSize = new Size(moduleWidth, moduleWidth);

    for (int i = 0; i < code.moduleCount; i++) {
      var offY = i * moduleWidth;

      for (int j = 0; j < code.moduleCount; j++) {
        var offX = j * moduleWidth;

        var moduleRect = new Offset(offX, offY) & moduleSize;

        canvas.drawRect(
          moduleRect,
          new Paint()
            ..color = code.isDark(i, j) ? color : const Color(0x00FFFFFF)
            ..isAntiAlias = false,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
