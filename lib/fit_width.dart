import 'package:flutter/widgets.dart';

class FitWidth extends StatelessWidget {
  final Widget child;

  FitWidth({this.child});

  @override
  Widget build(BuildContext context) {
    return new Row(mainAxisSize: MainAxisSize.max, children: [
      new Expanded(
        child: new AspectRatio(aspectRatio: 1.0, child: child),
      )
    ]);
  }
}
