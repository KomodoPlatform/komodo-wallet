import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:komodo_cex_market_data/src/binance/data/binance_provider_interface.dart';
import 'package:komodo_cex_market_data/src/binance/models/binance_exchange_info.dart';
import 'package:komodo_cex_market_data/src/binance/models/binance_exchange_info_reduced.dart';
import 'package:komodo_cex_market_data/src/models/coin_ohlc.dart';

/// A provider class for fetching data from the Binance API.
class BinanceProvider implements IBinanceProvider {
  /// Creates a new BinanceProvider instance.
  const BinanceProvider({this.apiUrl = 'https://api.binance.com/api/v3'});

  /// The base URL for the Binance API.
  /// Defaults to 'https://api.binance.com/api/v3'.
  final String apiUrl;

  @override
  Future<CoinOhlc> fetchKlines(
    String symbol,
    String interval, {
    int? startUnixTimestampMilliseconds,
    int? endUnixTimestampMilliseconds,
    int? limit,
    String? baseUrl,
  }) async {
    final queryParameters = <String, dynamic>{
      'symbol': symbol,
      'interval': interval,
      if (startUnixTimestampMilliseconds != null)
        'startTime': startUnixTimestampMilliseconds.toString(),
      if (endUnixTimestampMilliseconds != null)
        'endTime': endUnixTimestampMilliseconds.toString(),
      if (limit != null) 'limit': limit.toString(),
    };

    final baseRequestUrl = baseUrl ?? apiUrl;
    final uri = Uri.parse('$baseRequestUrl/klines')
        .replace(queryParameters: queryParameters);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return CoinOhlc.fromJson(
        jsonDecode(response.body) as List<dynamic>,
      );
    } else {
      throw Exception(
        'Failed to load klines for \'$symbol\': '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  @override
  Future<BinanceExchangeInfoResponse> fetchExchangeInfo({
    String? baseUrl,
  }) async {
    final requestUrl = baseUrl ?? apiUrl;
    final response = await http.get(Uri.parse('$requestUrl/exchangeInfo'));

    if (response.statusCode == 200) {
      return BinanceExchangeInfoResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw http.ClientException(
        'Failed to load exchange info: ${response.statusCode} ${response.body}',
      );
    }
  }

  @override
  Future<BinanceExchangeInfoResponseReduced> fetchExchangeInfoReduced({
    String? baseUrl,
  }) async {
    final requestUrl = baseUrl ?? apiUrl;
    final response = await http.get(Uri.parse('$requestUrl/exchangeInfo'));

    if (response.statusCode == 200) {
      return BinanceExchangeInfoResponseReduced.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 451) {
      // service unavailable for legal reasons
      return BinanceExchangeInfoResponseReduced(
        timezone: '',
        serverTime: 0,
        symbols: List.empty(),
      );
    } else {
      throw http.ClientException(
        'Failed to load exchange info: ${response.statusCode} ${response.body}',
      );
    }
  }
}
