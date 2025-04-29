import 'package:komodo_cex_market_data/src/binance/models/symbol_reduced.dart';

/// Represents a reduced version of the response from the Binance Exchange Info
/// endpoint.
class BinanceExchangeInfoResponseReduced {
  BinanceExchangeInfoResponseReduced({
    required this.timezone,
    required this.serverTime,
    required this.symbols,
  });

  /// Creates a new instance of [BinanceExchangeInfoResponseReduced] from a JSON map.
  factory BinanceExchangeInfoResponseReduced.fromJson(
    Map<String, dynamic> json,
  ) {
    return BinanceExchangeInfoResponseReduced(
      timezone: json['timezone'] as String,
      serverTime: json['serverTime'] as int,
      symbols: (json['symbols'] as List<dynamic>)
          .map((dynamic v) => SymbolReduced.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  /// The timezone of the server. Defaults to 'UTC'.
  String timezone;

  /// The server time in Unix time (milliseconds).
  int serverTime;

  /// The list of symbols available on the exchange.
  List<SymbolReduced> symbols;
}
