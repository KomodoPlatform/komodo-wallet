import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';

/// Base class for all currencies
abstract class ICurrency {
  const ICurrency(this.symbol, this.name);

  final String symbol;
  final String name;

  /// Returns true if the currency is a fiat currency (e.g. USD)
  bool get isFiat;
  /// Returns true if the currency is a crypto currency (e.g. BTC)
  bool get isCrypto;

  /// Returns the abbreviation of the currency (e.g. BTC, USD).
  String getAbbr() => symbol;
  /// Returns the full name of the currency (e.g. Bitcoin).
  String formatNameShort() => name;
}

class FiatCurrency extends ICurrency {
  const FiatCurrency(super.symbol, super.name);

  @override
  bool get isFiat => true;

  @override
  bool get isCrypto => false;
}

class CryptoCurrency extends ICurrency {
  const CryptoCurrency(super.symbol, super.name, this.chainType);

  final CoinType chainType;

  @override
  bool get isFiat => false;

  @override
  bool get isCrypto => true;

  @override
  String getAbbr() {
    if (chainType == CoinType.utxo ||
        (chainType == CoinType.cosmos && symbol == 'ATOM') ||
        (chainType == CoinType.erc20 && symbol == 'ETH') ||
        (chainType == CoinType.bep20 && symbol == 'BNB') ||
        (chainType == CoinType.avx20 && symbol == 'AVAX') ||
        (chainType == CoinType.etc && symbol == 'ETC') ||
        (chainType == CoinType.ftm20 && symbol == 'FTM') ||
        (chainType == CoinType.arb20 && symbol == 'ARB') ||
        (chainType == CoinType.hrc20 && symbol == 'ONE') ||
        (chainType == CoinType.plg20 && symbol == 'MATIC') ||
        (chainType == CoinType.mvr20 && symbol == 'MOVR')) {
      return symbol;
    }

    return '$symbol-${getCoinTypeName(chainType).replaceAll('-', '')}';
  }

  @override
  String formatNameShort() {
    final coinType = ' (${getCoinTypeName(chainType)})';
    return '$name$coinType';
  }
}
