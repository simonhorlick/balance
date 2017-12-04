import 'dart:async';
import 'dart:convert';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

class Tx {
  Tx(this.description, this.amount, this.time, this.receive);

  final String description;
  final Int64 amount;
  final Int64 time;
  final bool receive;
}

const kNormalText = const TextStyle(
    fontSize: 18.0, color: Colors.black, decoration: TextDecoration.none);
const kNormalWhiteText = const TextStyle(
    fontSize: 18.0, color: Colors.white, decoration: TextDecoration.none);

const kLargeWhiteText = const TextStyle(
    fontSize: 24.0, color: Colors.white, decoration: TextDecoration.none);

const kBalanceText = const TextStyle(
    fontSize: 28.0, color: Colors.white, decoration: TextDecoration.none);

const kBalanceSubText = const TextStyle(
    fontSize: 16.0, color: const Color(0xE0FFFFFF), decoration: TextDecoration.none);

const kTitleText = const TextStyle(
    fontSize: 16.0, color: Colors.white, decoration: TextDecoration.none);

const kPaymentText = const TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 18.0,
    color: Colors.black,
    decoration: TextDecoration.none);

const kPriceText = const TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 18.0,
    color: Colors.black,
    decoration: TextDecoration.none);

const kSmallPriceText = const TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
    color: Colors.black87,
    decoration: TextDecoration.none);

var formatter = new NumberFormat("###,###", "en_US");
var fiatFormatter = new NumberFormat("###,###.00", "en_US");

class PaymentRow extends StatelessWidget {
  PaymentRow(this.transaction);

  final Tx transaction;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Row(children: [
                  new Icon(Icons.arrow_upward, size: 16.0),
                  new SizedBox.fromSize(size: new Size(10.0, 0.0)),
                  new Text(transaction.description, style: kPaymentText),
                ]),
                new Text(formatter.format(transaction.amount),
                    style: kPriceText),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                new Text(fiatFormatter.format(2.0), style: kSmallPriceText),
              ],
            ),
          ]),
    );
  }
}

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double topInset = MediaQuery.of(context).padding.top;
    return new Padding(
      padding: new EdgeInsets.only(top: topInset),
      child: new SizedBox.fromSize(
          size: new Size.fromHeight(50.0),
          child:
          new Center(child: new Text("balance", style: kNormalWhiteText))),
    );
  }
}

class Balance extends StatelessWidget {
  Balance(this.walletBalance, this.channelBalance);

  final Int64 walletBalance;
  final Int64 channelBalance;

  @override
  Widget build(BuildContext context) {
    return new Column(children: [
      new Text(formatter.format(walletBalance), style: kBalanceText),
      new SizedBox.fromSize(size: new Size.fromHeight(10.0)),
      new Text("spendable: " + formatter.format(channelBalance),
          style: kBalanceSubText),
    ]);
  }
}

class TopUp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.only(top: 50.0),
      child: new Center(
        child: new GestureDetector(
          onTap: () => _navigateToTopup(context),
            child: new Text("＋ Top-up from bitcoin wallet", style: kBalanceSubText)),
      ),
    );
  }

  _navigateToTopup(BuildContext context) {
    // TODO(simon): Implement.
    Navigator.of(context).pushNamed("/topup");
  }
}

class SendReceive extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new SizedBox.fromSize(
      size: new Size.fromHeight(90.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          new GestureDetector(onTap: () => _navigateToSend(context), child: new Text("SEND", style: kNormalWhiteText)),
          new GestureDetector(onTap: () => _navigateToReceive(context), child: new Text("RECEIVE", style: kNormalWhiteText)),
        ],
      ),
    );
  }

  void _navigateToSend(BuildContext context) {
    Navigator.of(context).pushNamed("/scan");
  }

  void _navigateToReceive(BuildContext context) {
    // TODO(simon): Implement.
  }
}

class Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new SizedBox.fromSize(
        size: new Size.fromHeight(70.0),
        child: new Container(
            color: Colors.white,
            child: new Center(
                child:
                new Icon(Icons.keyboard_arrow_down, color: Colors.blue))));
  }
}

class InfoContent extends StatelessWidget {
  InfoContent(this.balancePane);

  final Widget balancePane;

  @override
  Widget build(BuildContext context) {
    return new Expanded(
      child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        balancePane,
        new TopUp(),
      ]),
    );
  }
}

class WalletInfoPane extends StatelessWidget {
  WalletInfoPane(this.balancePane);

  final Widget balancePane;

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.blue,
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            new Header(),
            // All children have fixed size apart from InfoContent that fills
            // the remaining space.
            new InfoContent(balancePane),
            new SendReceive(),
            new Footer(),
          ]),
    );
  }
}

class WalletImpl extends StatelessWidget {
  WalletImpl(this.walletBalance, this.channelBalance, this.payments);

  final Int64 walletBalance;
  final Int64 channelBalance;
  final List<Tx> payments;

  @override
  Widget build(BuildContext context) {
    var balancePane = new Balance(walletBalance, channelBalance);

    return new Container(
      color: Colors.white,
      child: new CustomScrollView(slivers: [
        new SliverFillViewport(
          delegate:
          new SliverChildBuilderDelegate((BuildContext context, int index) {
            return new WalletInfoPane(balancePane);
          }, childCount: 1),
          viewportFraction: 1.0,
        ),
        new SliverFixedExtentList(
          itemExtent: 70.0,
          delegate: new SliverChildBuilderDelegate(
                (BuildContext context, int index) {
              return new PaymentRow(payments[index]);
            },
            childCount: payments.length,
          ),
        ),
        new SliverPadding(padding: new EdgeInsets.only(bottom: 100.0))
      ]),
    );
  }
}

class Wallet extends StatefulWidget {

  Wallet(this.stub);

  final LightningClient stub;

  @override
  _WalletState createState() => new _WalletState();
}

class _WalletState extends State<Wallet> {

  Int64 walletBalance;
  Int64 channelBalance;

  List<Tx> payments;

  bool ready = false;

  paymentToTx(Payment p) {
    return new Tx("Payment", p.value, p.creationDate, false);
  }

  Future refresh() async {
    var walletBalanceResponse = await widget.stub.walletBalance(WalletBalanceRequest.create());
    var channelBalanceResponse = await widget.stub.channelBalance(ChannelBalanceRequest.create());
    var paymentsResponse = await widget.stub.listPayments(ListPaymentsRequest.create());

    setState(() {
      walletBalance = walletBalanceResponse.totalBalance;
      channelBalance = channelBalanceResponse.balance;
      payments = paymentsResponse.payments
          .map(paymentToTx)
          .toList()
          ..sort((a, b) => b.time.compareTo(a.time));
      ready = true;
    });

    return null;
  }

  @override
  initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return new Container();
    }

    return new WalletImpl(walletBalance, channelBalance, payments);
  }
}
