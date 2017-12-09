import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:balance/qr.dart';
import 'package:balance/rates.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class Receive extends StatelessWidget {
  Receive(this.stub);

  final LightningClient stub;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.blue,
      body: new Padding(
        padding: MediaQuery.of(context).padding,
        child: new Column(children: [
          new Align(
              alignment: Alignment.centerLeft,
              child: new BackButton(color: Colors.white)),
          new Keypad(stub),
        ]),
      ),
    );
  }
}

const kAmountStyle = const TextStyle(fontSize: 80.0, color: Colors.white);
const kAmountCurrencyStyle =
    const TextStyle(fontSize: 50.0, color: Colors.white);
const kKeyStyle = const TextStyle(fontSize: 32.0, color: Colors.white);
const kButtonStyle = const TextStyle(fontSize: 18.0, color: Colors.white);

var fiatFormatter = new NumberFormat("###,###", "en_US");

class Key extends StatelessWidget {
  Key(this.text, this._addDigit);

  final String text;
  final Function _addDigit;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () => _addDigit(text),
      behavior: HitTestBehavior.opaque,
      child: new Padding(
          padding: new EdgeInsets.all(20.0),
          child: new Text(text, style: kKeyStyle)),
    );
  }
}

class RequestButton extends StatelessWidget {
  final GestureTapCallback _onTap;

  RequestButton(this._onTap);

  @override
  Widget build(BuildContext context) {
    return new Flex(
      direction: Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Expanded(
            child: new GestureDetector(
          onTap: _onTap,
          child: new Container(
              decoration: new BoxDecoration(color: new Color(0x20FFFFFF)),
              child: new Padding(
                  padding: new EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 25.0),
                  child: new Center(
                      child: new Text("REQUEST", style: kButtonStyle)))),
        )),
      ],
    );
  }
}

class Keypad extends StatefulWidget {
  final LightningClient stub;

  Keypad(this.stub);

  @override
  _KeypadState createState() => new _KeypadState();
}

class _KeypadState extends State<Keypad> {
  String _digits = "0";

  void _addDigit(String digit) {
    setState(() {
      _digits += digit;
      // Strip any prefixed zeros.
      if (_digits.startsWith("0")) {
        _digits = _digits.substring(1);
      }
    });
  }

  void _decimalPoint(String ignored) {
    // If a decimal point has already been entered, then ignore this.
    if (_digits.contains(".")) return;
    setState(() {
      _digits += ".";
    });
  }

  void _backspace() {
    setState(() {
      if (_digits.length == 1) {
        _digits = "0";
      } else {
        _digits = _digits.substring(0, _digits.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              new Padding(
                  padding: new EdgeInsets.only(top: 8.0),
                  child: new Text("\$", style: kAmountCurrencyStyle)),
              new Text(_digits,
                  overflow: TextOverflow.fade, style: kAmountStyle)
            ]),
        new Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new Key("1", _addDigit),
            new Key("2", _addDigit),
            new Key("3", _addDigit),
          ],
        ),
        new Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new Key("4", _addDigit),
            new Key("5", _addDigit),
            new Key("6", _addDigit),
          ],
        ),
        new Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new Key("7", _addDigit),
            new Key("8", _addDigit),
            new Key("9", _addDigit),
          ],
        ),
        new Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new Key(".", _decimalPoint),
            new Key("0", _addDigit),

            // The backspace button.
            new GestureDetector(
              onTap: _backspace,
              behavior: HitTestBehavior.opaque,
              child: new Padding(
                  padding: new EdgeInsets.all(20.0),
                  child: new Icon(Icons.backspace, color: Colors.white)),
            )
          ],
        ),
        new Padding(
          padding: new EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 0.0),
          child: new RequestButton(_request),
        )
      ],
    );
  }

  Future<Null> _request() async {
    var result = await Navigator.of(context).push(new MaterialPageRoute<bool>(
          builder: (BuildContext context) =>
              new PaymentRequestScreen(_digits, widget.stub),
          fullscreenDialog: true,
        ));
  }
}

const kTitleText = const TextStyle(
    fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white);

class PaymentRequestScreen extends StatefulWidget {
  final String digits;
  final LightningClient stub;

  PaymentRequestScreen(this.digits, this.stub);

  @override
  _PaymentRequestScreenState createState() => new _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  Future<AddInvoiceResponse> response;
  Rates rates = new FakeRates();

  @override
  initState() {
    super.initState();

    var amountFiat = double.parse(widget.digits);
    var satoshis = rates.satoshis(amountFiat);

    setState(() {
      response = widget.stub.addInvoice(Invoice.create()
        ..memo = ""
        ..value = new Int64(satoshis));
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        backgroundColor: Colors.blue,
        body: new Column(children: [
          new Padding(
              padding:
                  new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: new Align(
                  alignment: Alignment.centerLeft,
                  child: new BackButton(color: Colors.white))),
          new Expanded(
            child: new FutureBuilder<AddInvoiceResponse>(
              future: response,
              builder: (BuildContext context,
                  AsyncSnapshot<AddInvoiceResponse> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return new Text('ConnectionState.none');
                  case ConnectionState.waiting:
                    return new Text('ConnectionState.waiting');
                  default:
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    else
                      return new Page(snapshot.data.paymentRequest);
                }
              },
            ),
          ),
        ]));
  }
}

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

class Page extends StatelessWidget {
  final String paymentRequest;

  Page(this.paymentRequest);

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        new Text('REQUEST', style: kTitleText),
        new Padding(
            padding: new EdgeInsets.all(20.0),
            child: new FitWidth(child: new QrCodeWidget(paymentRequest)))
      ],
    );
  }
}
