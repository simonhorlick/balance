import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:grpc/grpc.dart';

import 'generated/rpc.pbgrpc.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:convert/convert.dart';

/// A ChannelWrapper calls the listChannels RPC on initialisation then renders
/// nothing until the RPC returns.
class ChannelWrapper extends StatefulWidget {
  const ChannelWrapper(this.stub);
  final LightningClient stub;
  @override
  _ChannelWrapperState createState() => new _ChannelWrapperState();
}

class _ChannelWrapperState extends State<ChannelWrapper> {
  List<ActiveChannel> channels;
  List<PendingChannelResponse_ClosedChannel> closedChannels;
  List<PendingChannelResponse_PendingOpenChannel> openingChannels;
  List<PendingChannelResponse_ForceClosedChannel> forceClosedChannels;

  Timer pollingTimer;

  @override
  initState() {
    super.initState();
    refreshChannels();

    pollingTimer = new Timer.periodic(new Duration(seconds: 1), (timer) {
      refreshChannels();
    });
  }

  @override
  void deactivate() {
    pollingTimer.cancel();
    super.deactivate();
  }

  void refreshChannels() {
    widget.stub
        .listChannels(ListChannelsRequest.create())
        .then((response) => setState(() {
              channels = response.channels;
            }))
        .catchError((error) => print("listChannels failed"));

    widget.stub
        .pendingChannels(PendingChannelRequest.create())
        .then((response) => setState(() {
              closedChannels = response.pendingClosingChannels;
              openingChannels = response.pendingOpenChannels;
              forceClosedChannels = response.pendingForceClosingChannels;
            }))
        .catchError((error) => print("pendingChannels failed"));
  }

  void makeChannel() {
    OpenChannelRequest request = OpenChannelRequest.create()
      ..nodePubkey = hex.decoder.convert(
          "03f3ae3c64338b0545ba12493421c6782aae7e43be7332f5658a5ae29cea0119da")
      ..localFundingAmount = new Int64(500000);
    widget.stub.openChannel(request).map(_processStatusUpdate);
  }

  _processStatusUpdate(OpenStatusUpdate event) {
    print(event);
  }

  void connect() {
    LightningAddress address = LightningAddress.create()
      ..pubkey =
          "03f3ae3c64338b0545ba12493421c6782aae7e43be7332f5658a5ae29cea0119da"
      ..host = "sg.horlick.me";
    ConnectPeerRequest request = ConnectPeerRequest.create()
      ..addr = address
      ..perm = true;
    widget.stub.connectPeer(request).then((response) {
      print(response);
    }).catchError((error) => print("connectPeer failed: $error"));
  }

  @override
  Widget build(BuildContext context) {
    var waitingForRpcs = channels == null || openingChannels == null;

    return waitingForRpcs
        ? new Center(child: new Text("Loading channels"))
        : (channels.isEmpty && openingChannels.isEmpty)
            ? new Center(
                child: new Column(children: <Widget>[
                new Text("No channels"),
                new GestureDetector(
                  onTap: connect,
                  child: new Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: new Text("Connect to peer")),
                ),
                new GestureDetector(
                  onTap: makeChannel,
                  child: new Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: new Text("Make a channel")),
                ),
              ]))
            : new Channels(channels, openingChannels);
  }
}

/// Channels is the main UI component for rendering a list of payment channels.
/// Note that this class is stateless to simplify its implementation.
class Channels extends StatelessWidget {
  Channels(this.channels, this.openingChannels);

  final List<ActiveChannel> channels;
  final List<PendingChannelResponse_PendingOpenChannel> openingChannels;

  Widget buildListTile(BuildContext context, ActiveChannel channel) {
    return new MergeSemantics(
      child: new ListTile(
        isThreeLine: true,
        dense: false,
        leading: new ExcludeSemantics(
            child: new CircleAvatar(child: new Text(channel.channelPoint))),
        title: new Text('${channel.channelPoint}',
            overflow: TextOverflow.ellipsis),
        subtitle: new Text(
          'Capacity is ${channel.capacity}, ours is ${channel.localBalance} theirs is ${channel.remoteBalance}',
        ),
        trailing: null,
      ),
    );
  }

  Widget buildOpeningListTile(
      BuildContext context, PendingChannelResponse_PendingOpenChannel channel) {
    return new MergeSemantics(
      child: new ListTile(
        isThreeLine: true,
        dense: false,
        leading: new ExcludeSemantics(
            child: new CircleAvatar(
                child: new Text("${channel.channel.channelPoint}"))),
        title: new Text('Pending: ${channel.channel.channelPoint}',
            overflow: TextOverflow.ellipsis),
        subtitle: new Text(
          'Capacity is ${channel.channel.capacity}, ours is ${channel.channel.localBalance} theirs is ${channel.channel.remoteBalance}',
        ),
        trailing: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> listTiles =
        channels.map((channel) => buildListTile(context, channel));
    Iterable<Widget> openingListTiles = openingChannels
        .map((channel) => buildOpeningListTile(context, channel));

    return new Scrollbar(
      child: new ListView(
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        children: openingListTiles.toList()..addAll(listTiles),
      ),
    );
  }
}
