import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:flutter/material.dart';

class Transactions extends StatefulWidget {
  const Transactions(this.stub);

  final LightningClient stub;

  @override
  _TransactionsState createState() => new _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  List<Payment> payments;
  List<Transaction> transactions;
  List<ActiveChannel> channels;

  void initState() {
    super.initState();
    widget.stub.getTransactions(GetTransactionsRequest.create()).then((response) {
      if (mounted) {
        setState(() {
          transactions = response.transactions;
        });
        print("Transactions: $transactions");
      }
    });
    widget.stub.listChannels(ListChannelsRequest.create()).then((response) {
      if (mounted) {
        setState(() {
          channels = response.channels;
        });
        print("Channels: $channels");
      }
    });
    widget.stub.listPayments(ListPaymentsRequest.create()).then((response) {
      // If the user navigates between the wallet and channel tabs, the
      // transactions tab is quickly initialised where this method gets called
      // then the tab flies out of view and is destroyed. As listPayments is
      // likely still in-flight after the widget is destroyed, we need to check
      // if it's still mounted here.
      if (!mounted) {
        print("NOT MOUNTED!");
      } else {
        setState(() {
          payments = response.payments;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return (payments == null || this.transactions == null || this.channels == null) ? new Container() : new TransactionsList(payments, transactions, channels);
  }
}

class TransactionsList extends StatelessWidget {
  TransactionsList(this.payments, this.transactions, this.channels);

  final List<Payment> payments;
  final List<Transaction> transactions;
  final List<ActiveChannel> channels;

  Widget buildListTile(BuildContext context, Payment payment) {
    return new MergeSemantics(
      child: new ListTile(
        isThreeLine: true,
        dense: false,
        leading: new ExcludeSemantics(
            child: new Icon(Icons.arrow_upward)),
        title: new Text("LN payment", overflow: TextOverflow.ellipsis),
        subtitle: payment.fee > 0 ? new Text('fee ${payment.fee}') : new Container(),
        trailing: new Text("${payment.value}"),
      ),
    );
  }

  Widget buildTxTile(BuildContext context, Transaction tx) {
    // These are the on-chain transactions, either channel funding tx's or
    // wallet deposits.

    var sentOrReceived = tx.amount > 0 ? "Deposit" : "Sent";
    var icon = tx.amount > 0 ? new Icon(Icons.arrow_downward) : new Icon(Icons.arrow_upward);

    return new MergeSemantics(
      child: new ListTile(
        isThreeLine: true,
        dense: false,
        leading: new ExcludeSemantics(
            child: icon),
        title: new Text("$sentOrReceived"),
        subtitle: tx.totalFees > 0 ? new Text('fee ${tx.totalFees}', overflow: TextOverflow.ellipsis) : new Container(),
        trailing: new Text('${tx.amount.abs()}'),
      ),
    );
  }

  Widget buildFundingTile(BuildContext context, Transaction tx) {
    // These are the on-chain transactions, either channel funding tx's or
    // wallet deposits.

    var sentOrReceived = tx.amount > 0 ? "Deposit" : "Channel Fee";
    var icon = tx.amount > 0 ? new Icon(Icons.arrow_downward) : new Icon(Icons.arrow_upward);

    return new MergeSemantics(
      child: new ListTile(
        isThreeLine: true,
        dense: false,
        leading: new ExcludeSemantics(child: icon),
        title: new Text("$sentOrReceived"),
        subtitle: new Text(""),
        trailing: new Text('${tx.totalFees}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> paymentTiles =
        payments.map((payment) => buildListTile(context, payment));

    // Treat channel funding transactions separately from deposits and on-chain
    // transactions.

    var isFunding = (tx) {
      // determine if this is a funding tx
      for(ActiveChannel chan in channels) {
        if (chan.channelPoint.contains(tx.txHash)) {
          return true;
        }
      }
      return false;
    };

    Iterable<Transaction> funding = transactions.where(isFunding);

    Iterable<Widget> fundingTiles =
        funding.map((tx) => buildFundingTile(context, tx));

    Iterable<Widget> txTiles =
      transactions
          .where((tx) => !isFunding(tx))
          .map((tx) => buildTxTile(context, tx));

    var emptyTransactionsView = new Container(
      child: new Center(child: new Text("No transactions.")),
    );

    return paymentTiles.isEmpty
        ? emptyTransactionsView
        : new Scrollbar(
            child: new ListView(
              padding: new EdgeInsets.symmetric(vertical: 8.0),
              children: []..addAll(paymentTiles)..addAll(fundingTiles)..addAll(txTiles),
            ),
          );
  }
}
