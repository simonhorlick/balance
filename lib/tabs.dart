import 'package:balance/channels.dart';
import 'package:balance/wallet.dart';
import 'package:balance/generated/rpc.pbgrpc.dart';
import 'package:balance/transactions.dart';
import 'package:flutter/material.dart';

class _Page {
  _Page({this.text, this.widget});
  final String text;
  final Widget widget;
}

class Tabs extends StatefulWidget {
  Tabs(this.stub);

  final LightningClient stub;

  @override
  TabsState createState() => new TabsState();
}

class TabsState extends State<Tabs> with SingleTickerProviderStateMixin {
  TabController _controller;
  String barcode;
  List<_Page> _allPages;

  @override
  void initState() {
    super.initState();
    _allPages = <_Page>[
      new _Page(text: 'WALLET', widget: new Wallet(widget.stub)),
      new _Page(text: 'TRANSACTIONS', widget: new Transactions(widget.stub)),
      new _Page(text: 'CHANNELS', widget: new ChannelWrapper(widget.stub)),
    ];
    _controller = new TabController(vsync: this, length: _allPages.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void scan() {
    Navigator.of(context).pushNamed("/scan");
  }

  void handleMenuSelection(String value) {
    print(value);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('app'),
        bottom: new TabBar(
          controller: _controller,
          isScrollable: true,
          tabs: _allPages.map((_Page page) {
            return new Tab(text: page.text);
          }).toList(),
        ),
      ),
      body: new TabBarView(
          controller: _controller,
          children: _allPages.map((_Page page) {
            return new Container(
              padding: const EdgeInsets.all(12.0),
              child: page.widget,
            );
          }).toList()),
      floatingActionButton: new FloatingActionButton(
        onPressed: scan,
        tooltip: 'Scan a barcode',
        child: new Icon(Icons.add_a_photo),
      ),
    );
  }
}
