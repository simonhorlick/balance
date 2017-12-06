abstract class Rates {
  int satoshis(double fiatValue);

  double fiat(int satoshis);
}

class FakeRates implements Rates {
  static const fiatPerBitcoin = 12689.87;
  static const satoshisPerBitcoin = 1e8;

  @override
  int satoshis(double amountFiat) {
    return ((satoshisPerBitcoin * amountFiat) / fiatPerBitcoin).ceil();
  }

  @override
  double fiat(int satoshis) {
    return satoshis * (fiatPerBitcoin / satoshisPerBitcoin);
  }
}
