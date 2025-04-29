import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
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

  // Returns the abbreviation of the currency without postfixes like "-segwit"
  String get configSymbol;

  /// Returns the full name of the currency (e.g. Bitcoin).
  String formatNameShort() => name;

  ICurrency copyWith({
    String? symbol,
    String? name,
  });
}

class FiatCurrency extends ICurrency {
  const FiatCurrency(super.symbol, super.name);

  @override
  bool get isFiat => true;

  @override
  bool get isCrypto => false;

  
  @override
  String get configSymbol => symbol;

  @override
  FiatCurrency copyWith({
    String? symbol,
    String? name,
  }) {
    return FiatCurrency(
      symbol ?? this.symbol,
      name ?? this.name,
    );
  }
}

class CryptoCurrency extends ICurrency {
  const CryptoCurrency(super.symbol, super.name, this.chainType);

  factory CryptoCurrency.fromAsset(Asset asset) {
    final coin = asset.toCoin();
    return CryptoCurrency(
      coin.id.id,
      coin.name,
      coin.type,
    );
  }

  final CoinType chainType;

  @override
  bool get isFiat => false;

  @override
  bool get isCrypto => true;

  @override
  String get configSymbol => symbol.split('-')[0];

  @override
  String getAbbr() {
    return symbol;

    // TODO: figure out if this is still necessary
    // return '$symbol-${getCoinTypeName(chainType).replaceAll('-', '')}';
  }

  @override
  String formatNameShort() {
    final coinType = ' (${getCoinTypeName(chainType)})';
    return '$name$coinType';
  }

  Asset toAsset(KomodoDefiSdk sdk) {
    return sdk.getSdkAsset(getAbbr());
  }

  @override
  CryptoCurrency copyWith({
    String? symbol,
    String? name,
    CoinType? chainType,
  }) {
    return CryptoCurrency(
      symbol ?? this.symbol,
      name ?? this.name,
      chainType ?? this.chainType,
    );
  }
}
