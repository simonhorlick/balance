import 'dart:async';

import 'package:balance/balance_app.dart';
import 'package:balance/daemon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pbgrpc.dart';

// An OnboardingPage consists of a main body with a "next" button at the bottom
// of the screen, allowing the user to progress through the onboarding.
class OnboardingPage extends StatelessWidget {
  OnboardingPage(this.body, this.next);

  final Widget body;
  final Function next;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Column(
        children: <Widget>[
          new Expanded(child: body),
          new SizedBox.fromSize(
            size: const Size.fromHeight(90.0),
            child: new Padding(
              padding: new EdgeInsets.all(20.0),
              child: new GestureDetector(
                  onTap: next,
                  child: new Container(
                      decoration: new BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: new BorderRadius.circular(8.0),
                      ),
                      child: new Center(
                          child: new Text("Next",
                              style: new TextStyle(
                                  color: Colors.white, fontSize: 17.0))))),
            ),
          ),
        ],
      ),
    );
  }
}

const kTitleText = const TextStyle(
    fontSize: 50.0,
    color: Colors.black,
    fontWeight: FontWeight.w900,
    letterSpacing: -3.0);

const kTitleAccentText = const TextStyle(
    fontSize: 50.0,
    color: Colors.redAccent,
    fontWeight: FontWeight.w900,
    letterSpacing: -3.0,
    height: 0.6);

const kNormalText = const TextStyle(fontSize: 18.0, color: Colors.black);

class HelloScreen extends StatelessWidget {
  void _next(BuildContext context) {
    Navigator.of(context).pushReplacement(new PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return new MnemonicScreen();
        },
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return new FadeTransition(
            opacity: animation,
            child: new SlideTransition(
              position: new Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: const Offset(0.0, 0.0))
                  .animate(animation),
              child: child,
            ),
          );
        }));
  }

  @override
  Widget build(BuildContext context) {
    var page = new Padding(
      padding: new EdgeInsets.all(20.0),
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            new Text("Welcome to", style: kTitleText),
            new Text("Balance", style: kTitleText),
            new SizedBox.fromSize(size: new Size.fromHeight(40.0)),
            new Text(
                "Balance is a new way of sending value cheaply and instantly.",
                style: kNormalText),
            new SizedBox.fromSize(size: new Size.fromHeight(20.0)),
            new Text(
                "Your payments are routed through the lightning network, a new global, interconnected financial system.",
                style: kNormalText),
            new SizedBox.fromSize(size: new Size.fromHeight(20.0)),
            new Text(
                "The next screens will create a new wallet that you can use to send and receive funds.",
                style: kNormalText),
          ]),
    );

    return new OnboardingPage(page, () => _next(context));
  }
}

class MnemonicScreen extends StatefulWidget {
  @override
  _MnemonicScreenState createState() => new _MnemonicScreenState();
}

class _MnemonicScreenState extends State<MnemonicScreen> {

  Future<List<String>> mnemonic;

  @override
  void initState() {
    super.initState();
    mnemonic = Daemon.createMnemonic();
  }

  _next(BuildContext context) {
    mnemonic.then((mnemonic) {
      // Create a new wallet with this mnemonic.
      Daemon.start(mnemonic.reduce((value, element) => value + " " + element));

      Navigator.of(context).pushReplacement(new PageRouteBuilder(
          opaque: false,
          pageBuilder: (BuildContext context, _, __) {
            return new FundingScreen();
          },
          transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
            return new FadeTransition(
              opacity: animation,
              child: new SlideTransition(
                position: new Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: const Offset(0.0, 0.0))
                    .animate(animation),
                child: child,
              ),
            );
          }));
    });
  }

  @override
  Widget build(BuildContext context) {
    var wordListBuilder = new FutureBuilder<List<String>>(
      future: mnemonic,
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
       switch (snapshot.connectionState) {
         case ConnectionState.none:
         case ConnectionState.waiting: return new Text('Generating wallet...', style: kNormalText);
         default:
           if (snapshot.hasError)
             return new Text('Error: ${snapshot.error}', style: kNormalText);
           else
             return new Text(
                   snapshot.data.reduce((a,b) => a + '\n' + b),
                   textAlign: TextAlign.center,
                   style: kNormalText,
           );
       }
      },
    );

    var page = new Padding(
      padding: new EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 0.0),
      child:
        new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            new Text(
                "Carefully write down the following sequence of words on a piece of paper and store it in a safe place.\n\n"
                "If your phone is lost or damaged, this will be the only way to recover your funds.\n\n",
                style: kNormalText),
            new Center(child: new FittedBox(
                fit: BoxFit.scaleDown,
                child: wordListBuilder
            )),
            ]
        )
    );

    return new OnboardingPage(page, () => _next(context));
  }
}

class FundingScreen extends StatefulWidget {
  @override
  _FundingScreenState createState() => new _FundingScreenState();
}

class _FundingScreenState extends State<FundingScreen> {

  String address;

  _next(BuildContext context) {
    Navigator.of(context).pushReplacement(new PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return new BalanceApp();
        },
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return new FadeTransition(
            opacity: animation,
            child: new SlideTransition(
              position: new Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: const Offset(0.0, 0.0))
                  .animate(animation),
              child: child,
            ),
          );
        }));
  }

  @override
  void initState() {
    super.initState();
    var stub = Daemon.connect();

    var req = NewAddressRequest.create()..type = NewAddressRequest_AddressType.NESTED_PUBKEY_HASH;
    stub.newAddress(req).then((response) {
      setState(() {
        address = response.address;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    var page = new Padding(
      padding: new EdgeInsets.all(20.0),
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            new Text(
                "Send funds to the following address to begin using your wallet.\n\n"
                    "This should take a few minutes, but could take up to an hour.",
                style: kNormalText),
            new Center(child: address == null ? new Text("Generating address...", style: kNormalText) : new TextField(controller: new TextEditingController(text: "$address"))),
          ]),
    );

    return new OnboardingPage(page, () => _next(context));
  }
}