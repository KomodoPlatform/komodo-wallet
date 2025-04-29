import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:komodo_cex_market_data/src/models/models.dart';

/// A class for fetching prices from Komodo API.
class KomodoPriceProvider {
  /// Creates a new instance of [KomodoPriceProvider].
  KomodoPriceProvider({
    this.mainTickersUrl =
        'https://defi-stats.komodo.earth/api/v3/prices/tickers_v2?expire_at=600',
  });

  /// The URL to fetch the main tickers from.
  final String mainTickersUrl;

  /// Fetches prices from Komodo API.
  ///
  /// Returns a map of coin IDs to their prices.
  ///
  /// Throws an error if the request fails.
  ///
  /// Example:
  /// ```dart
  /// final Map<String, CexPrice>? prices =
  ///   await cexPriceProvider.getLegacyKomodoPrices();
  /// ```
  Future<Map<String, CexPrice>> getKomodoPrices() async {
    final mainUri = Uri.parse(mainTickersUrl);

    http.Response res;
    String body;
    res = await http.get(mainUri);
    body = res.body;

    final json = jsonDecode(body) as Map<String, dynamic>?;

    if (json == null) {
      throw Exception('Invalid response from Komodo API: empty JSON');
    }

    final prices = <String, CexPrice>{};
    json.forEach((String priceTicker, dynamic pricesData) {
      prices[priceTicker] =
          CexPrice.fromJson(priceTicker, pricesData as Map<String, dynamic>);
    });
    return prices;
  }
}
