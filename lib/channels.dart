import 'dart:async';

import 'package:flutter/material.dart';

import 'package:grpc/grpc.dart';

import 'generated/rpc.pbgrpc.dart';
import 'package:flutter/services.dart' show rootBundle;

/// A StubWrapper renders nothing until the provided stub is non-null. This
/// allows children to rely on the passed stub in their initState methods.
class StubWrapper extends StatefulWidget {
  const StubWrapper({Key key, LightningClient stub})
      : stub = stub,
        super(key: key);
  final LightningClient stub;
  @override
  _StubWrapperState createState() => new _StubWrapperState();
}

class _StubWrapperState extends State<StubWrapper> {
  @override
  Widget build(BuildContext context) {
    return widget.stub == null
        ? new Text("Loading RPC")
        : new ChannelWrapper(stub: widget.stub);
  }
}

/// A ChannelWrapper calls the listChannels RPC on initialisation then renders
/// nothing until the RPC returns.
class ChannelWrapper extends StatefulWidget {
  const ChannelWrapper({Key key, LightningClient stub})
      : stub = stub,
        super(key: key);
  final LightningClient stub;
  @override
  _ChannelWrapperState createState() => new _ChannelWrapperState();
}

class _ChannelWrapperState extends State<ChannelWrapper> {
  List<ActiveChannel> channels;

  @override
  initState() {
    super.initState();
    widget.stub
        .listChannels(ListChannelsRequest.create())
        .then((response) => setState(() {
              channels = response.channels;
            }));
  }

  @override
  Widget build(BuildContext context) {
    return channels == null
        ? new Text("Calling listChannels")
        : channels.isEmpty
            ? new Center(child: new Text("No channels"))
            : new Channels(channels);
  }
}

/// Channels is the main UI component for rendering a list of payment channels.
/// Note that this class is stateless to simplify its implementation.
class Channels extends StatelessWidget {
  Channels(this.channels);

  final List<ActiveChannel> channels;

  Widget buildListTile(BuildContext context, ActiveChannel channel) {
    return new MergeSemantics(
      child: new ListTile(
        isThreeLine: true,
        dense: false,
        leading: new ExcludeSemantics(
            child: new CircleAvatar(child: new Text(channel.channelPoint))),
        title: new Text('This item represents ${channel.channelPoint}.'),
        subtitle: new Text(
          'Capacity is ${channel.capacity}, ours is ${channel.localBalance} theirs is ${channel.remoteBalance}',
        ),
        trailing: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> listTiles =
        channels.map((channel) => buildListTile(context, channel));

    return new Scrollbar(
      child: new ListView(
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        children: listTiles.toList(),
      ),
    );
  }
}
