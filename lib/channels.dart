import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:balance/lnd.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

const kBaseText = const TextStyle(
  fontFamily: '.SF UI Display',
  fontWeight: FontWeight.normal,
  fontSize: 18.0,
  color: Colors.white,
  decoration: TextDecoration.none,
);

var kNormalText = kBaseText.copyWith(
  fontSize: 16.0,
  color: Colors.white,
);
var kDarkText = kBaseText.copyWith(
  fontSize: 16.0,
  color: Colors.blue,
);

var formatter = new NumberFormat("###,###", "en_US");

class Channels extends StatefulWidget {
  @override
  _ChannelsState createState() => new _ChannelsState();
}

class _ChannelsState extends State<Channels> {
  ListChannelsResponse listChannelsResponse;

  @override
  Future<Null> refresh() async {
    ListChannelsResponse response =
        await LndClient.listChannels(ListChannelsRequest.create());
    setState(() {
      listChannelsResponse = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (listChannelsResponse == null) {
      return new Container();
    }

    var channelRows = listChannelsResponse.channels.map((chan) {
      var filled = new Container(
        decoration:
            new BoxDecoration(border: new Border.all(color: Colors.white)),
        child: new Padding(
          padding: new EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 8.0),
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Text("${formatter.format(chan.localBalance)}",
                    style: kNormalText),
                new Text("${formatter.format(chan.remoteBalance)}",
                    style: kNormalText),
              ]),
        ),
      );

      var unfilled = new Container(
        decoration: new BoxDecoration(
            border: new Border.all(color: Colors.white), color: Colors.white),
        child: new Padding(
          padding: new EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 8.0),
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Text("${formatter.format(chan.localBalance)}",
                    style: kDarkText),
                new Text("${formatter.format(chan.remoteBalance)}",
                    style: kDarkText),
              ]),
        ),
      );

      var channelBalancePct = 1.0 -
          chan.localBalance.toDouble() /
              (chan.localBalance + chan.remoteBalance).toDouble();

      return new Stack(children: [
        filled,
        new ClipRect(
            child: unfilled, clipper: new BoxClipper(channelBalancePct))
      ]);
    }).toList();

    return new Container(
        color: Colors.blue,
        child: new Padding(
            padding: new EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 0.0),
            child: new Column(children: channelRows)));
  }
}

class BoxClipper extends CustomClipper<Rect> {
  BoxClipper(this.fillPercent);

  double fillPercent;

  @override
  Rect getClip(Size size) {
    return new Rect.fromLTWH(0.0, 0.0, size.width * fillPercent, size.height);
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) => false;
}
