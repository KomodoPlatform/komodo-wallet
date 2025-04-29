import 'package:equatable/equatable.dart';

/// Represents Open-High-Low-Close (OHLC) data.
class CoinOhlc extends Equatable {
  /// Creates a new instance of [CoinOhlc].
  const CoinOhlc({required this.ohlc});

  /// Creates a new instance of [CoinOhlc] from a JSON array.
  factory CoinOhlc.fromJson(List<dynamic> json) {
    return CoinOhlc(
      ohlc: json
          .map((dynamic kline) => Ohlc.fromJson(kline as List<dynamic>))
          .toList(),
    );
  }

  /// Creates a new instance of [CoinOhlc] with constant price data between
  /// [startAt] and [endAt] with an interval of [intervalSeconds].
  factory CoinOhlc.fromConstantPrice({
    required DateTime startAt,
    required DateTime endAt,
    required int intervalSeconds,
    double constantValue = 1.0,
  }) {
    final coinOhlc = CoinOhlc(
      ohlc: List.generate(
        (endAt.difference(startAt).inSeconds / intervalSeconds).ceil(),
        (index) {
          final time = startAt.add(
            Duration(seconds: index * intervalSeconds),
          );
          return Ohlc(
            high: constantValue,
            low: constantValue,
            open: constantValue,
            close: constantValue,
            openTime: time.millisecondsSinceEpoch,
            closeTime: time.millisecondsSinceEpoch,
          );
        },
      ),
    );

    coinOhlc.ohlc.add(
      Ohlc(
        high: constantValue,
        low: constantValue,
        open: constantValue,
        close: constantValue,
        openTime: endAt.millisecondsSinceEpoch,
        closeTime: endAt.millisecondsSinceEpoch,
      ),
    );

    return coinOhlc;
  }

  /// The list of klines (candlestick data).
  final List<Ohlc> ohlc;

  /// Converts the [CoinOhlc] object to a JSON array.
  List<dynamic> toJson() {
    return ohlc.map((Ohlc kline) => kline.toJson()).toList();
  }

  @override
  List<Object?> get props => <Object?>[ohlc];
}

/// Extension for converting a list of [Ohlc] objects to a `CoinOhlc` object.

extension OhlcListToCoinOhlc on List<Ohlc> {
  /// Converts a list of [Ohlc] objects to a `CoinOhlc` object.
  CoinOhlc toCoinOhlc() {
    return CoinOhlc(ohlc: this);
  }
}

/// Represents a Binance Kline (candlestick) data.
class Ohlc extends Equatable {
  /// Creates a new instance of [Ohlc].
  const Ohlc({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.closeTime,
    this.volume,
    this.quoteAssetVolume,
    this.numberOfTrades,
    this.takerBuyBaseAssetVolume,
    this.takerBuyQuoteAssetVolume,
  });

  /// Creates a new instance of [Ohlc] from a JSON array.
  factory Ohlc.fromJson(List<dynamic> json) {
    return Ohlc(
      openTime: json[0] as int,
      open: double.parse(json[1] as String),
      high: double.parse(json[2] as String),
      low: double.parse(json[3] as String),
      close: double.parse(json[4] as String),
      volume: double.parse(json[5] as String),
      closeTime: json[6] as int,
      quoteAssetVolume: double.parse(json[7] as String),
      numberOfTrades: json[8] as int,
      takerBuyBaseAssetVolume: double.parse(json[9] as String),
      takerBuyQuoteAssetVolume: double.parse(json[10] as String),
    );
  }

  /// Converts the [Ohlc] object to a JSON array.
  List<dynamic> toJson() {
    return <dynamic>[
      openTime,
      open,
      high,
      low,
      close,
      volume,
      closeTime,
      quoteAssetVolume,
      numberOfTrades,
      takerBuyBaseAssetVolume,
      takerBuyQuoteAssetVolume,
    ];
  }

  /// Converts the kline data into a JSON object like that returned in the previously used OHLC endpoint.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'timestamp': openTime,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      'quote_volume': quoteAssetVolume,
    };
  }

  /// The opening time of the kline as a Unix timestamp since epoch (UTC).
  final int openTime;

  /// The opening price of the kline.
  final double open;

  /// The highest price reached during the kline.
  final double high;

  /// The lowest price reached during the kline.
  final double low;

  /// The closing price of the kline.
  final double close;

  /// The trading volume during the kline.
  final double? volume;

  /// The closing time of the kline.
  final int closeTime;

  /// The quote asset volume during the kline.
  final double? quoteAssetVolume;

  /// The number of trades executed during the kline.
  final int? numberOfTrades;

  /// The volume of the asset bought by takers during the kline.
  final double? takerBuyBaseAssetVolume;

  /// The quote asset volume of the asset bought by takers during the kline.
  final double? takerBuyQuoteAssetVolume;

  @override
  List<Object?> get props => <Object?>[
        openTime,
        open,
        high,
        low,
        close,
        volume,
        closeTime,
        quoteAssetVolume,
        numberOfTrades,
        takerBuyBaseAssetVolume,
        takerBuyQuoteAssetVolume,
      ];
}
