import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// The number of satoshis in one bitcoin.
const kSatoshisPerBitcoin = 100000000;

/// An instance of Rates allows clients to convert between satoshis and a fiat
/// currency.
abstract class Rates {

  /// Returns the number of satoshis that you would receive for selling the
  /// given amount of fiat.
  int satoshis(double fiatValue);

  /// Returns the fiat value of the provided number of satoshis.
  double fiat(int satoshis);
}

/// A hard-coded implementation of Rates, for testing.
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

/// An implementation of Rates that queries the bitstamp exchange for the
/// current bitcoin USD rate when it is initialised, and uses that rate for
/// all further calculations.
class BitstampRates implements Rates {
  final double fiatPerBitcoin;

  BitstampRates(this.fiatPerBitcoin);

  static Future<double> getRate() async {
    // Query the bitstamp public API for the current bid price. This would be
    // the price that a merchant would receive if they were to immediately
    // liquidate the bitcoin in a payment request.
    // For documentation, see https://www.bitstamp.net/api/.
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

  /// Use this method to construct BitstampRates instances.
  static Future<Rates> create() async {
    return new BitstampRates(await getRate());
  }
}
