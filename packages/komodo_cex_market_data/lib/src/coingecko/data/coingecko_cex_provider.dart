import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/coin_historical_data.dart';

/// A class for fetching data from CoinGecko API.
class CoinGeckoCexProvider {
  /// Creates a new instance of [CoinGeckoCexProvider].
  CoinGeckoCexProvider({
    this.baseUrl = 'api.coingecko.com',
    this.apiVersion = '/api/v3',
  });

  /// The base URL for the CoinGecko API.
  final String baseUrl;

  /// The API version for the CoinGecko API.
  final String apiVersion;

  /// Fetches the list of coins supported by CoinGecko.
  ///
  /// [includePlatforms] Include platform contract addresses.
  Future<List<CexCoin>> fetchCoinList({bool includePlatforms = false}) async {
    final queryParameters = <String, String>{
      'include_platform': includePlatforms.toString(),
    };
    final uri = Uri.https(baseUrl, '$apiVersion/coins/list', queryParameters);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final coins = jsonDecode(response.body) as List<dynamic>;
      return coins
          .map(
            (dynamic element) =>
                CexCoin.fromJson(element as Map<String, dynamic>),
          )
          .toList();
    } else {
      throw Exception(
        'Failed to load coin list: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Fetches the list of supported vs currencies.
  Future<List<String>> fetchSupportedVsCurrencies() async {
    final uri =
        Uri.https(baseUrl, '$apiVersion/simple/supported_vs_currencies');

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final currencies = jsonDecode(response.body) as List<dynamic>;
      return currencies.map((dynamic currency) => currency as String).toList();
    } else {
      throw Exception(
        'Failed to load supported vs currencies: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Fetches the market data for a specific currency.
  ///
  /// [vsCurrency] The target currency of market data (usd, eur, jpy, etc.).
  /// [ids] The ids of the coins, comma separated.
  /// [category] The category of the coins.
  /// [order] The order of the coins.
  /// [perPage] Total results per page.
  /// [page] Page through results.
  /// [sparkline] Include sparkline 7 days data.
  /// [priceChangePercentage] Comma-sepa
  /// [locale] The localization of the market data.
  /// [precision] The price's precision.
  Future<List<CoinMarketData>> fetchCoinMarketData({
    String vsCurrency = 'usd',
    List<String>? ids,
    String? category,
    String order = 'market_cap_asc',
    int perPage = 100,
    int page = 1,
    bool sparkline = false,
    String? priceChangePercentage,
    String locale = 'en',
    String? precision,
  }) {
    final queryParameters = <String, String>{
      'vs_currency': vsCurrency,
      if (ids != null) 'ids': ids.join(','),
      if (category != null) 'category': category,
      'order': order,
      'per_page': perPage.toString(),
      'page': page.toString(),
      'sparkline': sparkline.toString(),
      if (priceChangePercentage != null)
        'price_change_percentage': priceChangePercentage,
      'locale': locale,
      if (precision != null) 'price_change_percentage': precision,
    };
    final uri =
        Uri.https(baseUrl, '$apiVersion/coins/markets', queryParameters);

    return http.get(uri).then((http.Response response) {
      if (response.statusCode == 200) {
        final coins = jsonDecode(response.body) as List<dynamic>;
        return coins
            .map(
              (dynamic element) =>
                  CoinMarketData.fromJson(element as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Failed to load coin market data: ${response.statusCode} ${response.body}',
        );
      }
    });
  }

  /// Fetches the market chart data for a specific currency.
  ///
  /// [id] The id of the coin.
  /// [vsCurrency] The target currency of market data (usd, eur, jpy, etc.).
  /// [fromUnixTimestamp] From date in UNIX Timestamp.
  /// [toUnixTimestamp] To date in UNIX Timestamp.
  /// [precision] The price's precision.
  Future<CoinMarketChart> fetchCoinMarketChart({
    required String id,
    required String vsCurrency,
    required int fromUnixTimestamp,
    required int toUnixTimestamp,
    String? precision,
  }) {
    final queryParameters = <String, String>{
      'vs_currency': vsCurrency,
      'from': fromUnixTimestamp.toString(),
      'to': toUnixTimestamp.toString(),
      if (precision != null) 'precision': precision,
    };
    final uri = Uri.https(
      baseUrl,
      '$apiVersion/coins/$id/market_chart/range',
      queryParameters,
    );

    return http.get(uri).then((http.Response response) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CoinMarketChart.fromJson(data);
      } else {
        throw Exception(
          'Failed to load coin market chart: ${response.statusCode} ${response.body}',
        );
      }
    });
  }

  /// Fetches the market chart data for a specific currency.
  ///
  /// [id] The id of the coin.
  /// [vsCurrency] The target currency of market data (usd, eur, jpy, etc.).
  /// [date] The date of the market data to fetch.
  /// [localization] Include all the localized languages in response. Defaults to false.
  Future<CoinHistoricalData> fetchCoinHistoricalMarketData({
    required String id,
    required DateTime date,
    String vsCurrency = 'usd',
    bool localization = false,
  }) {
    final queryParameters = <String, String>{
      'date': _formatDate(date),
      'localization': localization.toString(),
    };
    final uri = Uri.https(
      baseUrl,
      '$apiVersion/coins/$id/history',
      queryParameters,
    );

    return http.get(uri).then((http.Response response) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CoinHistoricalData.fromJson(data);
      } else {
        throw Exception(
          'Failed to load coin market chart: ${response.statusCode} ${response.body}',
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day-$month-$year';
  }

  /// Fetches prices from CoinGecko API.
  /// The CoinGecko API is used as a fallback when the Komodo API is down.
  ///
  /// The [coinGeckoIds] are the CoinGecko IDs of the coins to fetch prices for.
  /// The [vsCurrencies] is a comma-separated list of currencies to compare to.
  ///
  /// Returns a map of coingecko IDs to their [CexPrice]s.
  ///
  /// Throws an error if the request fails.
  ///
  /// Example:
  /// ```dart
  /// final prices = await cexPriceProvider.getCoinGeckoPrices(
  ///  ['bitcoin', 'ethereum'],
  /// );
  Future<Map<String, CexPrice>> fetchCoinPrices(
    List<String> coinGeckoIds, {
    List<String> vsCurrencies = const <String>['usd'],
  }) async {
    final currencies = vsCurrencies.join(',');
    coinGeckoIds.removeWhere((String id) => id.isEmpty);

    final tickersUrl = Uri.https(baseUrl, '$apiVersion/simple/price', {
      'ids': coinGeckoIds.join(','),
      'vs_currencies': currencies,
    });

    final res = await http.get(tickersUrl);
    final body = res.body;

    final json = jsonDecode(body) as Map<String, dynamic>?;
    if (json == null) {
      throw Exception('Invalid response from CoinGecko API: empty JSON');
    }

    final prices = <String, CexPrice>{};
    json.forEach((String coingeckoId, dynamic pricesData) {
      if (coingeckoId == 'test-coin') {
        return;
      }

      // TODO(Francois): map to multiple currencies, or only allow 1 vs currency
      final price = (pricesData as Map<String, dynamic>)['usd'] as num?;

      prices[coingeckoId] = CexPrice(
        ticker: coingeckoId,
        price: price?.toDouble() ?? 0,
      );
    });

    return prices;
  }

  /// Fetches the ohlc data for a specific currency.
  ///
  /// [id] The id of the coin.
  /// [vsCurrency] The target currency of market data (usd, eur, jpy, etc.).
  /// [days] Data up to number of days ago.
  /// [precision] The price's precision.
  Future<CoinOhlc> fetchCoinOhlc(
    String id,
    String vsCurrency,
    int days, {
    int? precision,
  }) {
    final queryParameters = <String, String>{
      'id': id,
      'vs_currency': vsCurrency,
      'days': days.toString(),
      if (precision != null) 'precision': precision.toString(),
    };

    final uri = Uri.https(
      baseUrl,
      '$apiVersion/coins/$id/ohlc',
      queryParameters,
    );

    return http.get(uri).then((http.Response response) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return CoinOhlc.fromJson(data);
      } else {
        throw Exception(
          'Failed to load coin ohlc data: ${response.statusCode} ${response.body}',
        );
      }
    });
  }
}
