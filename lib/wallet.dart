import 'dart:async';
import 'dart:convert';

import 'package:balance/daemon.dart';
import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';
import 'package:balance/rates.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

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
    fontSize: 16.0, color: Colors.black54, decoration: TextDecoration.none);

var formatter = new NumberFormat("###,###", "en_US");
var fiatFormatter = new NumberFormat.currency(symbol: "\$");
var dateFormatter = new DateFormat("dd/MM 'at' HH:mm:ss", "en_US");

class PaymentRow extends StatelessWidget {
  PaymentRow(this.transaction, this.rates);

  final Tx transaction;
  final Rates rates;

  @override
  Widget build(BuildContext context) {
    var icon = new Padding(
      padding: new EdgeInsets.fromLTRB(0.0, 10.0, 10.0, 10.0),
      child: new Icon(
          transaction.receive ? Icons.arrow_downward : Icons.arrow_upward,
          size: 16.0),
    );

    var details =
        new Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          new Text(transaction.description, style: kPaymentText),
          new Text(formatter.format(transaction.amount), style: kPriceText),
        ],
      ),
      new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          new Text(
              "${dateFormatter.format(new DateTime.fromMillisecondsSinceEpoch(transaction.time.toInt()*1000))}",
              style: kSmallPriceText),
          rates == null
              ? new Text("")
              : new Text(
                  "${fiatFormatter.format(rates.fiat(transaction.amount.toInt()))}",
                  style: kSmallPriceText)
        ],
      ),
    ]);

    return new Container(
      color: Colors.white,
      child: new Padding(
        padding: new EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        child: new Row(children: [
          icon,
          new Expanded(child: details),
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
          child: new Stack(children: [
            // TODO(simon): Add back later when we have something to show here.
            //new GestureDetector(
            //  onTap: () => Scaffold.of(context).openDrawer(),
            //  child: new Padding(
            //      padding: new EdgeInsets.all(12.0),
            //      child: new Icon(Icons.menu, color: Colors.white)),
            //),
            new Center(child: new Text("balance", style: kTitleText)),
          ])),
    );
  }
}

class Balance extends StatelessWidget {
  Balance(this.walletBalance, this.channelBalance, this.info);

  // This is the value that is contained only within the wallet.
  final Int64 walletBalance;

  // This is the value that is contained only within the channels.
  final Int64 channelBalance;

  final GetInfoResponse info;

  @override
  Widget build(BuildContext context) {
    var elements = new List<Widget>();

    // Always show the balance at the top of the screen.
    elements.add(new Padding(
      padding: new EdgeInsets.only(bottom: 10.0),
      child: new Text(formatter.format(walletBalance + channelBalance),
          style: kBalanceText),
    ));

    // If the chain backend hasn't finished syncing yet, then show a progress
    // indicator.
    if (!info.syncedToChain) {
      elements.add(new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          new SizedBox(
              width: 10.0,
              height: 10.0,
              child: new CircularProgressIndicator(
                strokeWidth: 1.0,
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
              )),
          new Padding(
              padding: new EdgeInsets.only(left: 10.0),
              child:
                  new Text("Downloading blockchain (height ${info.blockHeight})", style: kBalanceSubText)),
        ],
      ));
    }

    // If the user doesn't have any channels yet, then display a "connecting to
    // network" message.
    if (info.numActiveChannels == 0) {
      elements.add(new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          new SizedBox(
              width: 10.0,
              height: 10.0,
              child: new CircularProgressIndicator(
                strokeWidth: 1.0,
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
              )),
          new Padding(
              padding: new EdgeInsets.only(left: 10.0),
              child: new Text("Connecting to network", style: kBalanceSubText)),
        ],
      ));
    }

    // If we're synced and have at least one channel, then display the spendable
    // amount that we have in our channels.
    if (info.syncedToChain && info.numActiveChannels > 0) {
      elements.add(new Text("Spendable: " + formatter.format(channelBalance),
          style: kBalanceSubText));
    }

    return new Column(children: elements);
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
  WalletImpl(this.walletBalance, this.channelBalance, this.transactions,
      this.info, this.rates);

  final Int64 walletBalance;
  final Int64 channelBalance;
  final List<Tx> transactions;
  final GetInfoResponse info;
  final Rates rates;

  @override
  Widget build(BuildContext context) {
    var balancePane = new Balance(walletBalance, channelBalance, info);

    var drawItems = new ListView(children: [
      new Text("Balance",
          style: new TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold)),
      new SizedBox.fromSize(size: new Size.fromHeight(20.0)),
      new GestureDetector(
          onTap: () => Navigator.of(context).pushNamed("/channels"),
          child: new Text("Channels", style: new TextStyle(fontSize: 20.0))),
    ]);

    return new Scaffold(
//      drawer: new Drawer(
//          child: new Padding(
//              padding: new EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 0.0),
//              child: drawItems)),
      body: new Stack(
        children: [
          // This element is shown when the user overscrolls the CustomScrollView.
          // This ensures they see the correct background colour in the direction
          // they're scrolling in.
          new Flex(direction: Axis.vertical, children: [
            new Expanded(child: new Container(color: Colors.blue)),
            new Expanded(child: new Container(color: Colors.white)),
          ]),
          new CustomScrollView(slivers: [
            new SliverList(
                delegate: new SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
              if (index == 0) {
                return new SizedBox.fromSize(
                    size: MediaQuery.of(context).size,
                    child: new WalletInfoPane(balancePane));
              } else {
                var txIndex = index - 1;
                return new SizedBox.fromSize(
                    size: new Size.fromHeight(70.0),
                    child: new PaymentRow(transactions[txIndex], rates));
              }
            }, childCount: transactions.length + 1)),
            new SliverToBoxAdapter(
                child: new SizedBox.fromSize(
                    size: new Size.fromHeight(200.0),
                    child: new Container(color: Colors.white))),
          ]),
        ],
      ),
    );
  }
}

class Wallet extends StatefulWidget {
  Wallet(this.stub);

  final LightningClient stub;

  @override
  _WalletState createState() => new _WalletState();
}

class _WalletState extends DaemonPoller<Wallet> {
  Int64 walletBalance;
  Int64 channelBalance;

  GetInfoResponse info;

  List<Tx> transactions;

  bool ready = false;

  Rates rates;

  paymentToTx(Payment p) {
    return new Tx("Sent", p.value, p.creationDate, false);
  }

  invoiceToTx(Invoice inv) {
    return new Tx("Received", inv.value, inv.creationDate, true);
  }

  /// Called if the chain has just become synchronised.
  void hasSyncedToChain() {
    print("wallet: hasSyncedToChain");

    // Add a well-known peer in case something goes wrong with bootstrapping.
    var addr = LightningAddress.create()
      ..host = "172.104.59.47"
      ..pubkey =
          "038b869a90060ca856ac80ec54c20acebca93df1869fbee9550efeb238b964558c";

    // This has to happen after the chain backend has finished syncing or the
    // rpc will fail.
    widget.stub
        .connectPeer(ConnectPeerRequest.create()
          ..perm = true
          ..addr = addr)
        .then((response) {
      print("connected: $response");
    }).catchError((error) {
      print("error connecting to peer: $error");
    });
  }

  @override
  Future<Null> refresh() async {
    print("wallet: Refreshing state");

    try {
      var walletBalanceResponse =
          await widget.stub.walletBalance(WalletBalanceRequest.create());
      var channelBalanceResponse =
          await widget.stub.channelBalance(ChannelBalanceRequest.create());
      var paymentsResponse =
          await widget.stub.listPayments(ListPaymentsRequest.create());
      var invoicesResponse =
          await widget.stub.listInvoices(ListInvoiceRequest.create());
      var infoResponse = await widget.stub.getInfo(GetInfoRequest.create());

      if (infoResponse.syncedToChain && (info == null || !info.syncedToChain)) {
        hasSyncedToChain();
      }

      setState(() {
        walletBalance = walletBalanceResponse.totalBalance;
        channelBalance = channelBalanceResponse.balance;

        var invoices = invoicesResponse.invoices
            .where((inv) => inv.settled)
            .map(invoiceToTx)
            .toList();
        var payments = paymentsResponse.payments.map(paymentToTx).toList();

        transactions = invoices
          ..addAll(payments)
          ..sort((a, b) => b.time.compareTo(a.time));

        info = infoResponse;

        ready = true;
      });
    } catch (error) {
      print("$error");
    }

    return null;
  }

  @override
  initState() {
    super.initState();
    BitstampRates.create().then((r) => setState(() {
          rates = r;
        }));
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return new Container();
    }

    return new WalletImpl(
        walletBalance, channelBalance, transactions, info, rates);
  }
}
