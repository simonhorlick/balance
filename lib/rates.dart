import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const kSatoshisPerBitcoin = 100000000;

abstract class Rates {
  int satoshis(double fiatValue);

  double fiat(int satoshis);
}

class FakeRates implements Rates {
  static const fiatPerBitcoin = 16500.0;

  @override
  int satoshis(double amountFiat) {
    return ((kSatoshisPerBitcoin * amountFiat) / fiatPerBitcoin).ceil();
  }

  @override
  double fiat(int satoshis) {
    return satoshis * (fiatPerBitcoin / kSatoshisPerBitcoin);
  }
}

class BitstampRates implements Rates {
  final double fiatPerBitcoin;

  BitstampRates(this.fiatPerBitcoin);

  static Future<double> getRate() async {
    var response =
        await http.read("https://www.bitstamp.net/api/v2/ticker/btcusd");

    Map jsonData = JSON.decode(response);

    return double.parse(jsonData['bid']);
  }

  @override
  int satoshis(double amountFiat) {
    return ((kSatoshisPerBitcoin * amountFiat) / fiatPerBitcoin).ceil();
  }

  @override
  double fiat(int satoshis) {
    return satoshis * (fiatPerBitcoin / kSatoshisPerBitcoin);
  }

  static Future<Rates> create() async {
    return new BitstampRates(await getRate());
  }
}
