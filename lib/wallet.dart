import 'dart:async';
import 'dart:convert';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class Tx {
  Tx(this.description, this.amount, this.time, this.receive);

  final String description;
  final Int64 amount;
  final Int64 time;
  final bool receive;
}

const kBaseText = const TextStyle(
  fontFamily: '.SF UI Display',
  fontWeight: FontWeight.normal,
  fontSize: 18.0,
  color: Colors.white,
);

var kNormalWhiteText = kBaseText.copyWith(decoration: TextDecoration.none);

var kLargeWhiteText =
    kBaseText.copyWith(fontSize: 24.0, decoration: TextDecoration.none);

var kBalanceText =
    kBaseText.copyWith(fontSize: 32.0, decoration: TextDecoration.none);

var kBalanceSubText = kBaseText.copyWith(
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
    color: const Color(0xE0FFFFFF),
    decoration: TextDecoration.none);

var kTitleText = kBaseText.copyWith(
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.underline,
    decorationStyle: TextDecorationStyle.solid,
    decorationColor: Colors.white);

var kPaymentText =
    kBaseText.copyWith(color: Colors.black, decoration: TextDecoration.none);

var kPriceText =
    kBaseText.copyWith(color: Colors.black, decoration: TextDecoration.none);

var kSmallPriceText = kBaseText.copyWith(
    fontSize: 16.0, color: Colors.black87, decoration: TextDecoration.none);

var formatter = new NumberFormat("###,###", "en_US");
var fiatFormatter = new NumberFormat("###,###.00", "en_US");

class PaymentRow extends StatelessWidget {
  PaymentRow(this.transaction);

  final Tx transaction;

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.white,
      child: new Padding(
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
      ),
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
          child: new Center(child: new Text("balance", style: kTitleText))),
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
            child: new Text("＋ Top-up from bitcoin wallet",
                style: kBalanceSubText)),
      ),
    );
  }

  _navigateToTopup(BuildContext context) {
    // TODO(simon): Implement.
    Navigator.of(context).pushNamed("/topup");
  }
}

/// A button that expands the hit test area within the parent widget.
class ExpandedButton extends StatelessWidget {
  ExpandedButton(this.text, this.onTap);

  final String text;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return new Expanded(
      child: new GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: new Center(child: new Text(text, style: kNormalWhiteText))),
    );
  }
}

class SendReceive extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new SizedBox.fromSize(
      size: new Size.fromHeight(90.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          new ExpandedButton("SEND", () => _navigateToSend(context)),
          new ExpandedButton("RECEIVE", () => _navigateToReceive(context)),
        ],
      ),
    );
  }

  void _navigateToSend(BuildContext context) {
    Navigator.of(context).pushNamed("/scan");
  }

  void _navigateToReceive(BuildContext context) {
    Navigator.of(context).pushNamed("/receive");
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

    return new Stack(
      children: [
        // This element is shown when the user overscrolls the CustomScrollView.
        // This ensures they see the correct background colour in the direction
        // they're scrolling in.
        new Flex(direction: Axis.vertical, children: [
          new Expanded(child: new Container(color: Colors.blue)),
          new Expanded(child: new Container(color: Colors.white)),
        ]),
        new CustomScrollView(slivers: [
          new SliverFillViewport(
            delegate: new SliverChildBuilderDelegate(
                (BuildContext context, int index) {
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
          new SliverToBoxAdapter(
              child: new SizedBox.fromSize(
                  size: new Size.fromHeight(200.0),
                  child: new Container(color: Colors.white))),
        ]),
      ],
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
    var walletBalanceResponse =
        await widget.stub.walletBalance(WalletBalanceRequest.create());
    var channelBalanceResponse =
        await widget.stub.channelBalance(ChannelBalanceRequest.create());
    var paymentsResponse =
        await widget.stub.listPayments(ListPaymentsRequest.create());

    setState(() {
      walletBalance = walletBalanceResponse.totalBalance;
      channelBalance = channelBalanceResponse.balance;
      payments = paymentsResponse.payments.map(paymentToTx).toList()
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
