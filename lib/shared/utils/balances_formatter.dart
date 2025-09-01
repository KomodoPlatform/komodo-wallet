import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/model/coin.dart';

/// Calculates the fiat amount equivalent of the given [amount] of a [Coin] in USD.
///
/// The fiat amount is calculated by multiplying the [amount] with the USD price of the [Coin].
/// If the USD price is not available (`null`), it is treated as 0.00, and the resulting fiat amount will be 0.00.
///
/// Parameters:
/// - [coin] (Coin): The Coin for which the fiat amount needs to be calculated.
/// - [amount] (Rational): The amount of the Coin to be converted to fiat.
///
/// Return Value:
/// - (double): The equivalent fiat amount in USD based on the [amount] and the USD price of the [coin].
///
/// Example Usage:
/// ```dart
/// Coin bitcoin = Coin('BTC', usdPrice: Price(50000.0));
/// Rational amount = Rational.fromDouble(2.5);
/// double fiatAmount = getFiatAmount(bitcoin, amount);
/// print(fiatAmount); // Output: 125000.0 (USD)
/// ```
/// ```dart
/// Coin ethereum = Coin('ETH', usdPrice: Price(3000.0));
/// Rational amount = Rational.fromInt(10);
/// double fiatAmount = getFiatAmount(ethereum, amount);
/// print(fiatAmount); // Output: 30000.0 (USD)
/// ```
/// unit tests: [get_fiat_amount_tests]
double getFiatAmount(Coin coin, Rational amount) {
  final Decimal usdPrice = coin.usdPrice?.price ?? Decimal.zero;
  return (amount * usdPrice.toRational()).toDouble();
}
