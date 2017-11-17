// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:balance/channels.dart';
import 'package:balance/generated/rpc.pbgrpc.dart';
import 'package:balance/transactions.dart';
import 'package:flutter/material.dart';

enum TabsDemoStyle { textOnly }

class _Page {
  _Page({this.text, this.widget});
  final String text;
  final Widget widget;
}

final List<_Page> _allPages = <_Page>[
  new _Page(text: 'TRANSACTIONS', widget: new Transactions()),
  new _Page(text: 'CHANNELS', widget: new Channels()),
];

class Tabs extends StatefulWidget {
  static const String routeName = '/tabs';

  @override
  TabsState createState() => new TabsState();
}

class TabsState extends State<Tabs> with SingleTickerProviderStateMixin {
  TabController _controller;
  String barcode;

  @override
  void initState() {
    super.initState();
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
