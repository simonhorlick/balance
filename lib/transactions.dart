import 'dart:async';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

var formatter = new NumberFormat("###,###", "en_US");

class Transactions extends StatefulWidget {
  const Transactions(this.stub);

  final LightningClient stub;

  @override
  _TransactionsState createState() => new _TransactionsState();
}

class Tx {
  Tx(this.description, this.amount, this.time, this.receive);

  final String description;
  final Int64 amount;
  final Int64 time;
  final bool receive;
}

class Chan {
  Chan(this.ours);

  final ActiveChannel ours;
}

class _TransactionsState extends State<Transactions> {

  List<Tx> everything;

  List<Transaction> getAllNonFundingTransactions(
      List<ActiveChannel> channels, List<Transaction> transactions) {
    var isFunding = (tx) {
      // determine if this is a funding tx
      for (ActiveChannel chan in channels) {
        if (chan.channelPoint.contains(tx.txHash)) {
          return true;
        }
      }
      return false;
    };

    return transactions
        .where((tx) => !isFunding(tx))
        .toList();
  }

  List<Tx> listAllDepositsAndWithdrawls(
      List<ActiveChannel> channels, List<Transaction> transactions) {
    // GetTransactions returns a list of bitcoin transactions the wallet cares
    // about. This includes things like channel funding transactions and bitcoin
    // deposits that were made to the wallet.
    // FIXME(simon): Pending transactions are currently not shown.
    var trx = getAllNonFundingTransactions(channels, transactions);

    return trx
        .map((t) => new Tx(
            t.amount > 0 ? "Deposit" : "Withdrawl",
            t.amount.abs(),
            t.timeStamp,
            t.amount > 0))
        .toList();
  }

  Future<List<Tx>> listAllPayments() async {
    var payments = await widget.stub.listPayments(ListPaymentsRequest.create());

    return payments.payments
        .map((p) => new Tx("Payment", p.value, p.creationDate, false))
        .toList();
  }

  List<Tx> listAllChannelOpeningFees(
      List<ActiveChannel> channels, List<Transaction> transactions) {
    var isFunding = (tx) {
      // determine if this is a funding tx
      for (ActiveChannel chan in channels) {
        if (chan.channelPoint.contains(tx.txHash)) {
          return true;
        }
      }
      return false;
    };

    return transactions
        .where((tx) => isFunding(tx))
        .map((t) => new Tx(
            "Network Fee",
            t.totalFees,
            t.timeStamp,
            false))
        .toList();
  }

  Future<List<Tx>> listEverything() async {
    var chans = await widget.stub.listChannels(ListChannelsRequest.create());
    var trx = await widget.stub
        .getTransactions(GetTransactionsRequest.create());

    var channelOpens = listAllChannelOpeningFees(chans.channels, trx.transactions);
    var deposits = listAllDepositsAndWithdrawls(chans.channels, trx.transactions);
    var payments = await listAllPayments();

    return []
      ..addAll(channelOpens)
      ..addAll(deposits)
      ..addAll(payments)
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  void initState() {
    super.initState();

    listEverything().then((transactions) {
      if (!mounted) return;
      setState(() {
        everything = transactions;
      });
    });
  }

  Widget buildListTile(BuildContext context, Tx tx) {
    var icon = tx.receive ?
      new Icon(Icons.arrow_downward) :
      new Icon(Icons.arrow_upward);

    return new MergeSemantics(
      child: new ListTile(
        dense: false,
        leading: new ExcludeSemantics(child: icon),
        title: new Text("${tx.description}", overflow: TextOverflow.ellipsis),
        trailing: new Text("${formatter.format(tx.amount)}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return everything == null ? new Container() : new Scrollbar(
      child: new ListView(
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        children: everything.map((tx) => buildListTile(context, tx)).toList(),
      ),
    );
  }
}