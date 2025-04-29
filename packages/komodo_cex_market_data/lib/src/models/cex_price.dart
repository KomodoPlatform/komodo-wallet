import 'package:equatable/equatable.dart';

/// A class for representing a price from a CEX API.
class CexPrice extends Equatable {
  /// Creates a new instance of [CexPrice].
  const CexPrice({
    required this.ticker,
    required this.price,
    this.lastUpdated,
    this.priceProvider,
    this.change24h,
    this.changeProvider,
    this.volume24h,
    this.volumeProvider,
  });

  /// Creates a new instance of [CexPrice] from a JSON object.
  factory CexPrice.fromJson(String ticker, Map<String, dynamic> json) {
    return CexPrice(
      ticker: ticker,
      price: double.tryParse(json['last_price'] as String? ?? '') ?? 0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        (json['last_updated_timestamp'] as int?) ?? 0 * 1000,
      ),
      priceProvider: cexDataProvider(json['price_provider'] as String? ?? ''),
      change24h: double.tryParse(json['change_24h'] as String? ?? ''),
      changeProvider:
          cexDataProvider(json['change_24h_provider'] as String? ?? ''),
      volume24h: double.tryParse(json['volume24h'] as String? ?? ''),
      volumeProvider: cexDataProvider(json['volume_provider'] as String? ?? ''),
    );
  }

  /// The ticker of the price.
  final String ticker;

  /// The price of the ticker.
  final double price;

  /// The last time the price was updated.
  final DateTime? lastUpdated;

  /// The provider of the price.
  final CexDataProvider? priceProvider;

  /// The 24-hour volume of the ticker.
  final double? volume24h;

  /// The provider of the volume.
  final CexDataProvider? volumeProvider;

  /// The 24-hour change of the ticker.
  final double? change24h;

  /// The provider of the change.
  final CexDataProvider? changeProvider;

  /// Converts the [CexPrice] to a JSON object.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ticker: <String, dynamic>{
        'last_price': price,
        'last_updated_timestamp': lastUpdated,
        'price_provider': priceProvider,
        'volume24h': volume24h,
        'volume_provider': volumeProvider,
        'change_24h': change24h,
        'change_24h_provider': changeProvider,
      },
    };
  }

  @override
  String toString() {
    return 'CexPrice(ticker: $ticker, price: $price)';
  }

  @override
  List<Object?> get props => <Object?>[
        ticker,
        price,
        lastUpdated,
        priceProvider,
        volume24h,
        volumeProvider,
        change24h,
        changeProvider,
      ];
}

/// An enum for representing a CEX data provider.
enum CexDataProvider {
  /// Binance API.
  binance,

  /// CoinGecko API.
  coingecko,

  /// CoinMarketCap API.
  coinpaprika,

  /// CryptoCompare API.
  nomics,

  /// Unknown provider.
  unknown,
}

/// Returns a [CexDataProvider] from a string. If the string does not match any
/// of the known providers, [CexDataProvider.unknown] is returned.
CexDataProvider cexDataProvider(String string) {
  return CexDataProvider.values.firstWhere(
    (CexDataProvider e) => e.toString().split('.').last == string,
    orElse: () => CexDataProvider.unknown,
  );
}
