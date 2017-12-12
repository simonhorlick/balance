import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

import 'package:flutter/services.dart';

typedef void OnCopiedCallback();

const kMaxQrCodeLength = 230;

// The color used for a non-dark module in the QR code.
const kTransparentColor = const Color(0x00FFFFFF);

/// A QrCodeWidget constructs and draws a square QR-code of up to
/// kMaxQrCodeLength bytes.
class QrCodeWidget extends StatelessWidget {
  // The data the QR code holds.
  final String data;

  // The primary colour of the QR code, the rest of the space will be transparent.
  final Color color;

  // An optional callback for if the user has copied the QR code to the
  // clipboard by using a long-press gesture.
  final OnCopiedCallback onCopied;

  QrCodeWidget({this.data, this.color, this.onCopied}) {
    // This QR code generator hard-codes the version, this isn't currently a
    // problem because all QR codes we generate have a pre-determined length
    // below the max length limit.
    if (data.length > kMaxQrCodeLength) {
      throw new ArgumentError("QR code data is too long");
    }
  }

  @override
  Widget build(BuildContext context) {
    // See http://www.qrcode.com/en/about/version.html for more details on QR
    // code generation.
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

/// A QrCodePainter fills the provided space with a square QR-code.
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
            ..color = code.isDark(i, j) ? color : kTransparentColor
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
