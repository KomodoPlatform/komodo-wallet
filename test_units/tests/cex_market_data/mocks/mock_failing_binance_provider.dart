import 'package:flutter_test/flutter_test.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_cex_market_data/src/binance/models/binance_exchange_info_reduced.dart';

/// A mock class for testing a failing Binance provider
///  - all IPs blocked, or network issues
class MockFailingBinanceProvider implements IBinanceProvider {
  const MockFailingBinanceProvider();

  @override
  Future<BinanceExchangeInfoResponse> fetchExchangeInfo({String? baseUrl}) {
    throw UnsupportedError('Intentional exception');
  }

  @override
  Future<BinanceExchangeInfoResponseReduced> fetchExchangeInfoReduced({
    String? baseUrl,
  }) {
    throw UnsupportedError('Intentional exception');
  }

  @override
  Future<CoinOhlc> fetchKlines(
    String symbol,
    String interval, {
    int? startUnixTimestampMilliseconds,
    int? endUnixTimestampMilliseconds,
    int? limit,
    String? baseUrl,
  }) {
    throw UnsupportedError('Intentional exception');
  }
}
