import 'package:komodo_cex_market_data/src/binance/models/rate_limit.dart';
import 'package:komodo_cex_market_data/src/binance/models/symbol.dart';

/// Represents the response from the Binance Exchange Info API.
class BinanceExchangeInfoResponse {
  BinanceExchangeInfoResponse({
    required this.timezone,
    required this.serverTime,
    required this.rateLimits,
    required this.symbols,
  });

  /// Creates a new instance of [BinanceExchangeInfoResponse] from a JSON map.
  factory BinanceExchangeInfoResponse.fromJson(Map<String, dynamic> json) {
    return BinanceExchangeInfoResponse(
      timezone: json['timezone'] as String,
      serverTime: json['serverTime'] as int,
      rateLimits: (json['rateLimits'] as List<dynamic>)
          .map((dynamic v) => RateLimit.fromJson(v as Map<String, dynamic>))
          .toList(),
      symbols: (json['symbols'] as List<dynamic>)
          .map((dynamic v) => Symbol.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  /// The timezone of the server. Defaults to 'UTC'.
  String timezone;

  /// The server time in Unix time (milliseconds).
  int serverTime;

  /// The rate limit types for the API endpoints.
  List<RateLimit> rateLimits;

  /// The list of symbols available on the exchange.
  List<Symbol> symbols;
}
