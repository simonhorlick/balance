import 'dart:async';

import 'package:balance/fit_width.dart';
import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:balance/qr.dart';
import 'package:balance/rates.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const kAmountStyle = const TextStyle(fontSize: 80.0, color: Colors.white);
const kAmountCurrencyStyle =
    const TextStyle(fontSize: 50.0, color: Colors.white);
const kKeyStyle = const TextStyle(fontSize: 32.0, color: Colors.white);
const kButtonStyle = const TextStyle(fontSize: 18.0, color: Colors.white);

const kTitleText = const TextStyle(
    fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white);
const kNormalText = const TextStyle(fontSize: 16.0, color: Colors.white);

// FIXME(simon): This shouldn't be fixed to USD.
var fiatFormatter = new NumberFormat("###,###", "en_US");

/// A callback that is invoked when the user taps a keypad button.
typedef void KeyTapCallback(text);

/// The main "receive" screen. This is the flow that merchants will use to
/// accept lightning payments, yet still be able to price in their home
/// currency.
///
/// The high-level flow is as follows, the merchant:
///   1. enters the sale price in USD
///   2. hits request
///   3. shows the generated QR-code to the customer
///   4. checks back to ensure the payment has completed successfully
///
/// The first page in the flow, and this widget, implement a keypad for entering
/// the sale price.
class Receive extends StatelessWidget {
  final LightningClient stub;

  Receive(this.stub);

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

/// A key on the keypad.
class Key extends StatelessWidget {
  Key(this.text, this._addDigit);

  final String text;
  final KeyTapCallback _addDigit;

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

/// A RequestButton is a large and prominent button at the bottom of the screen.
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

/// A Keypad enables the user to enter a price in fiat currency. Therefore it's
/// also necessary to include a decimal point to allow cents.
///
/// The _KeypadState stores the currently typed value.
class Keypad extends StatefulWidget {
  final LightningClient stub;

  Keypad(this.stub);

  @override
  _KeypadState createState() => new _KeypadState();
}

class _KeypadState extends State<Keypad> {
  String _digits = "0";

  Future<Rates> rates;

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
  initState() {
    super.initState();

    // Find the FX rate now while the user is typing the amount.
    rates = BitstampRates.create();
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
    Navigator.of(context).pushReplacement(new MaterialPageRoute<bool>(
          builder: (BuildContext context) =>
              new PaymentRequestScreen(widget.stub, _digits, rates),
          fullscreenDialog: true,
        ));
  }
}

/// The PaymentRequestScreen creates an invoice from the supplied price, then
/// shows an InvoicePage.
class PaymentRequestScreen extends StatefulWidget {
  final String digits;
  final Future<Rates> rates;
  LightningClient stub;

  PaymentRequestScreen(this.stub, this.digits, this.rates);

  @override
  _PaymentRequestScreenState createState() => new _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  // The invoice that was generated.
  AddInvoiceResponse response;

  // An error message if the invoice could not be generated.
  String errorText;

  // Whether the invoice has been paid.
  bool settled = false;

  Timer timer;

  @override
  initState() {
    super.initState();

    widget.rates.then((fxRates) {
      print("Rate is currently ${fxRates.fiat(kSatoshisPerBitcoin)}");
      var amountFiat = double.parse(widget.digits);
      var satoshis = fxRates.satoshis(amountFiat);

      createInvoice(satoshis);
    }).catchError((error) {
      print("error: $error");
      setState(() {
        errorText = error.toString();
      });
    });
    timer = new Timer.periodic(new Duration(seconds: 1), (timer) {
      refresh();
    });
    refresh();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Future<Null> refresh() async {
    if (response != null) {
      var payReq = response.rHash;

      var inv =
          await widget.stub.lookupInvoice(PaymentHash.create()..rHash = payReq);

      print("$inv");

      setState(() {
        settled = inv.settled;
      });

      if (inv.settled) {
        print("Settled");
      } else {
        print("Not Settled");
      }
    }

    return null;
  }

  Future<Null> createInvoice(int satoshis) async {
    try {
      var invoiceResponse = await widget.stub.addInvoice(Invoice.create()
        ..memo = ""
        ..value = new Int64(satoshis));
      setState(() {
        response = invoiceResponse;
      });
    } catch (error) {
      setState(() {
        errorText = error.message;
      });
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    var content;

    if (errorText != null) {
      content = new Padding(
        padding: new EdgeInsets.all(20.0),
        child: new Center(child: new Text("$errorText", style: kNormalText)),
      );
    } else if (response == null) {
      content = new Center(
          child:
              new Text("Fetching current exchange rate.", style: kNormalText));
    } else if (settled == false) {
      content = new Expanded(child: new InvoicePage(response.paymentRequest));
    } else {
      content = new Expanded(child: new PaidPage());
    }

    return new Scaffold(
        backgroundColor: Colors.blue,
        body: new Column(children: [
          new Padding(
              padding:
                  new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: new Align(
                  alignment: Alignment.centerLeft,
                  child: new BackButton(color: Colors.white))),
          content,
        ]));
  }
}

/// A simple page notifying the merchant that the invoice has been paid.
class PaidPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        new Text('INVOICE', style: kTitleText),
        new Padding(
            padding: new EdgeInsets.all(20.0),
            child: new Text('Payment received.',
                style: kNormalText, textAlign: TextAlign.center)),
      ],
    );
  }
}

/// An InvoicePage displays a QR code that the customer must scan.
class InvoicePage extends StatelessWidget {
  // The BOLT #11 payment request string.
  final String paymentRequest;

  InvoicePage(this.paymentRequest);

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        new Text('INVOICE', style: kTitleText),
        new Padding(
            padding: new EdgeInsets.all(20.0),
            child: new Text('Please pay the invoice by scanning the QR code.',
                style: kNormalText, textAlign: TextAlign.center)),
        new Padding(
            padding: new EdgeInsets.all(20.0),
            child: new FitWidth(
                child: new QrCodeWidget(
                    data: paymentRequest, color: Colors.white)))
      ],
    );
  }
}
