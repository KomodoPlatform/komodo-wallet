import 'package:equatable/equatable.dart';
import 'package:komodo_cex_market_data/src/models/cex_coin.dart';

/// Represents a trading pair of coin on CEX exchanges, with the
/// [baseCoinTicker] as the coin being sold and [relCoinTicker] as the coin
/// being bought.
class CexCoinPair extends Equatable {
  /// Creates a new [CexCoinPair] with the given [baseCoinTicker] and
  /// [relCoinTicker].
  const CexCoinPair({
    required this.baseCoinTicker,
    required this.relCoinTicker,
  });

  factory CexCoinPair.fromJson(Map<String, dynamic> json) {
    return CexCoinPair(
      baseCoinTicker: json['baseCoinTicker'] as String,
      relCoinTicker: json['relCoinTicker'] as String,
    );
  }

  const CexCoinPair.usdtPrice(this.baseCoinTicker) : relCoinTicker = 'USDT';

  /// The ticker symbol of the coin being sold.
  final String baseCoinTicker;

  /// The ticker symbol of the coin being bought.
  final String relCoinTicker;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'baseCoinTicker': baseCoinTicker,
      'relCoinTicker': relCoinTicker,
    };
  }

  CexCoinPair copyWith({
    String? baseCoinTicker,
    String? relCoinTicker,
  }) {
    return CexCoinPair(
      baseCoinTicker: baseCoinTicker ?? this.baseCoinTicker,
      relCoinTicker: relCoinTicker ?? this.relCoinTicker,
    );
  }

  @override
  List<Object?> get props => <Object?>[baseCoinTicker, relCoinTicker];

  @override
  String toString() {
    return '$baseCoinTicker$relCoinTicker'.toUpperCase();
  }
}

/// An extension on [CexCoinPair] to check if the coin pair is supported by the
/// exchange given the list of supported coins.
extension CexCoinPairExtension on CexCoinPair {
  /// Returns `true` if the coin pair is supported by the exchange given the
  /// list of [supportedCoins].
  bool isCoinSupported(List<CexCoin> supportedCoins) {
    final baseCoinId = baseCoinTicker.toUpperCase();
    final relCoinId = relCoinTicker.toUpperCase();

    final cexCoin = supportedCoins
        .where(
          (supportedCoin) => supportedCoin.id.toUpperCase() == baseCoinId,
        )
        .firstOrNull;
    final isCoinSupported = cexCoin != null;

    final isFiatCoinInSupportedCurrencies = cexCoin?.currencies
            .where(
              (supportedVsCoin) => supportedVsCoin.toUpperCase() == relCoinId,
            )
            .isNotEmpty ??
        false;

    return isCoinSupported && isFiatCoinInSupportedCurrencies;
  }
}
