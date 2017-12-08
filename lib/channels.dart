import 'dart:async';

import 'package:balance/daemon.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:grpc/grpc.dart';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
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

class _ChannelWrapperState extends State<ChannelWrapper>
    with DaemonPoller<ChannelWrapper> {
  List<ActiveChannel> channels;
  List<PendingChannelResponse_ClosedChannel> closedChannels;
  List<PendingChannelResponse_PendingOpenChannel> openingChannels;
  List<PendingChannelResponse_ForceClosedChannel> forceClosedChannels;

  List<Peer> peers;

  @override
  Future<Null> refresh() {
    print("channels: Refreshing state");

    refreshChannels();
    refreshPeers();

    return null;
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
          "0294ceb8edf4b54da71caa506723dc8ab9c129ae19da4267f0e6d7cdcb396615b0")
      ..localFundingAmount = new Int64(500000);
    widget.stub.openChannel(request).map(_processStatusUpdate);
  }

  _processStatusUpdate(OpenStatusUpdate event) {
    print(event);
  }

  void connect() {
    LightningAddress address = LightningAddress.create()
      ..pubkey =
          "0294ceb8edf4b54da71caa506723dc8ab9c129ae19da4267f0e6d7cdcb396615b0"
      ..host = "sg.horlick.me";
    ConnectPeerRequest request = ConnectPeerRequest.create()
      ..addr = address
      ..perm = false;
    widget.stub.connectPeer(request).then((response) {
      print(response);
    }).catchError((error) => print("connectPeer failed: $error"));
  }

  void refreshPeers() {
    widget.stub.listPeers(ListPeersRequest.create()).then((response) {
      setState(() {
        peers = response.peers;
      });
    });
  }

  void disconnectAll() {
    widget.stub.listPeers(ListPeersRequest.create()).then((response) {
      response.peers.forEach((peer) {
        widget.stub.disconnectPeer(
            DisconnectPeerRequest.create()..pubKey = peer.pubKey);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var waitingForRpcs =
        channels == null || openingChannels == null || peers == null;

    return new Scaffold(
        body: waitingForRpcs
            ? new Center(child: new Text("Loading channels"))
            : (channels.isEmpty && openingChannels.isEmpty && peers.isEmpty)
                ? new Center(child: new Text("No connections."))
                : new Channels(
                    channels, openingChannels, peers, makeChannel, connect));
  }
}

/// Channels is the main UI component for rendering a list of payment channels.
/// Note that this class is stateless to simplify its implementation.
class Channels extends StatelessWidget {
  Channels(this.channels, this.openingChannels, this.peers, this.makeChannel,
      this.connect);

  final List<ActiveChannel> channels;
  final List<PendingChannelResponse_PendingOpenChannel> openingChannels;
  final List<Peer> peers;

  // For debugging.
  Function connect;
  Function makeChannel;

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

  Widget buildPeerTile(BuildContext context, Peer peer) {
    return new MergeSemantics(
      child: new ListTile(
        isThreeLine: true,
        dense: false,
        leading: new ExcludeSemantics(
            child: new CircleAvatar(child: new Text("${peer.peerId}"))),
        title:
            new Text('Peer: ${peer.pubKey}', overflow: TextOverflow.ellipsis),
        subtitle: new Text(
          'Sent ${peer.satSent}. Received ${peer.satRecv}',
        ),
        trailing: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> channelTiles =
        channels.map((channel) => buildListTile(context, channel));
    Iterable<Widget> openingListTiles = openingChannels
        .map((channel) => buildOpeningListTile(context, channel));

    peers.sort((a, b) => a.peerId.compareTo(b.peerId));
    Iterable<Widget> peerRows =
        peers.map((peer) => buildPeerTile(context, peer));

    return new Column(
      children: [
        new Padding(
          padding: MediaQuery.of(context).padding,
          child: new SizedBox.fromSize(
              size: new Size.fromHeight(40.0),
              child: new Stack(children: [
                new BackButton(),
                new Center(
                    child: new Text(
                  "Channels",
                  style: new TextStyle(fontWeight: FontWeight.bold),
                ))
              ])),
        ),
        new Expanded(
          child: new Scrollbar(
            child: new ListView(
                children: []
                  ..addAll(openingListTiles)
                  ..addAll(channelTiles)
                  ..addAll(peerRows)),
          ),
        )
      ],
    );
  }
}
