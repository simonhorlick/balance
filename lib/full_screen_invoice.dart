import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A FullScreenInvoice allows the user to paste an invoice string for the case
/// where scanning a QR code is not practical.
class FullScreenInvoice extends StatefulWidget {
  @override
  FullScreenInvoiceState createState() => new FullScreenInvoiceState();
}

class FullScreenInvoiceState extends State<FullScreenInvoice> {
  String invoice;
  @override
  Widget build(BuildContext context) {
    var textStyle =
        Theme.of(context).textTheme.subhead.copyWith(color: Colors.white);

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
          new Padding(
            padding: new EdgeInsets.all(10.0),
            child: new TextField(
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
            ),
          )
        ],
      )),
    );
  }
}
