import 'dart:async';
import 'dart:typed_data';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const MethodChannel _kChannel = const MethodChannel('rpc');

class TestWidget extends StatefulWidget {
  @override
  _TestWidgetState createState() => new _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  Future<GetInfoResponse> getInfo() async {
    var req = GetInfoRequest.create()..writeToBuffer();

    final Uint8List result =
        await _kChannel.invokeMethod('GetInfo', <String, dynamic>{
      'req': req,
    });

    return GetInfoResponse.create()..mergeFromBuffer(result);
  }

  @override
  initState() {
    super.initState();
    getInfo();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Balance',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new Container(child: new Text("This is text.")),
    );
  }
}
