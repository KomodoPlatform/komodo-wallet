import 'package:equatable/equatable.dart';

enum CexDataProvider {
  binance,
  coingecko,
  coinpaprika,
  nomics,
  unknown,
}

CexDataProvider cexDataProvider(String string) {
  return CexDataProvider.values.firstWhere(
      (e) => e.toString().split('.').last == string,
      orElse: () => CexDataProvider.unknown);
}

class CexPrice extends Equatable {
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

  final String ticker;
  final double price;
  final DateTime? lastUpdated;
  final CexDataProvider? priceProvider;
  final double? volume24h;
  final CexDataProvider? volumeProvider;
  final double? change24h;
  final CexDataProvider? changeProvider;

  @override
  String toString() {
    return 'CexPrice(ticker: $ticker, price: $price)';
  }

  factory CexPrice.fromJson(Map<String, dynamic> json) {
    return CexPrice(
      ticker: json['ticker'] as String,
      price: (json['price'] as num).toDouble(),
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
      priceProvider: cexDataProvider(json['priceProvider'] as String),
      volume24h: (json['volume24h'] as num?)?.toDouble(),
      volumeProvider: cexDataProvider(json['volumeProvider'] as String),
      change24h: (json['change24h'] as num?)?.toDouble(),
      changeProvider: cexDataProvider(json['changeProvider'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'price': price,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'priceProvider': priceProvider?.toString(),
      'volume24h': volume24h,
      'volumeProvider': volumeProvider?.toString(),
      'change24h': change24h,
      'changeProvider': changeProvider?.toString(),
    };
  }

  @override
  List<Object?> get props => [
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
