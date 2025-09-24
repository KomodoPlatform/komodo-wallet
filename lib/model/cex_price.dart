import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart' show Equatable;
import 'package:flutter/foundation.dart' show ValueGetter;
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart'
    as sdk_types;
import 'package:komodo_defi_types/komodo_defi_types.dart' show AssetId;

typedef CexDataProvider = sdk_types.CexDataProvider;

CexDataProvider cexDataProvider(String string) {
  return CexDataProvider.values.firstWhere(
    (e) => e.toString().split('.').last == string,
    orElse: () => CexDataProvider.unknown,
  );
}

@Deprecated(
  'Use the KomodoDefiSdk.marketData interface instead. '
  'This class will be removed in the future, and is only being kept during '
  'the transition to the new SDK.',
)
/// A temporary class to hold the price and change24h for a coin in a structure
/// similar to the one used in the legacy coins bloc during the transition to
/// to the SDK.
class CexPrice extends Equatable {
  const CexPrice({
    required this.assetId,
    required this.price,
    required this.change24h,
    required this.lastUpdated,
  });

  final AssetId assetId;
  final Decimal? price;
  final Decimal? change24h;
  final DateTime lastUpdated;

  @override
  List<Object?> get props => [assetId, price, change24h, lastUpdated];

  CexPrice copyWith({
    ValueGetter<Decimal>? price,
    ValueGetter<Decimal>? change24h,
    DateTime? lastUpdated,
  }) {
    return CexPrice(
      assetId: assetId,
      price: price?.call() ?? this.price,
      change24h: change24h?.call() ?? this.change24h,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Intentionally excluding to/from JSON methods since this class should not be
  // used outside of the legacy coins bloc, especially not for serialization.
}
