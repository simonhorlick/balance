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
  Int64 balance;

  @override
  initState() {
    super.initState();
    widget.stub
        .listChannels(ListChannelsRequest.create())
        .then((response) => setState(() {
              channels = response.channels;
            }))
        .catchError((error) => print("listChannels failed"));

    // This doesn't work. Not sure why.
    widget.stub.subscribeTransactions(GetTransactionsRequest.create()).listen(
        onTransaction,
        onError: (error) => print("subscribeTransactions failed $error"));

    refreshBalance();
  }

  void onTransaction(Transaction transaction) {
    print(transaction);
  }

  void refreshBalance() {
    widget.stub
        .walletBalance(WalletBalanceRequest.create()..witnessOnly = true)
        .then((response) {
      setState(() {
        balance = response.balance;
      });
    }).catchError((error) => print("walletBalance failed"));
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
    }).catchError((error) => print("connectPeer failed"));
  }

  void createAddress() {
    NewAddressRequest request = NewAddressRequest.create()
      ..type = NewAddressRequest_AddressType.NESTED_PUBKEY_HASH;
    widget.stub.newAddress(request).then((response) {
      print(response);
    }).catchError((error) => print("newAddress failed"));
  }

  @override
  Widget build(BuildContext context) {
    return channels == null
        ? new Center(child: new Text("Loading channels"))
        : channels.isEmpty
            ? new Center(
                child: new Column(children: <Widget>[
                new Text("No channels"),
                new Text("Balance is $balance"),
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
                new GestureDetector(
                  onTap: createAddress,
                  child: new Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: new Text("Create a new address")),
                )
              ]))
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
        title: new Text('${channel.channelPoint.substring(0,10)}...'),
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
