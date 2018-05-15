import 'package:balance/balance_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  // Make the status bar white.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  runApp(new BalanceApp());
}
