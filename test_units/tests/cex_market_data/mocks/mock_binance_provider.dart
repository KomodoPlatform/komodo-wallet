import 'package:flutter_test/flutter_test.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_cex_market_data/src/binance/models/binance_exchange_info_reduced.dart';

/// A mock class for testing a failing Binance provider
///  - all IPs blocked, or network issues
class MockBinanceProvider implements IBinanceProvider {
  const MockBinanceProvider();

  @override
  Future<BinanceExchangeInfoResponse> fetchExchangeInfo({String? baseUrl}) {
    throw UnsupportedError(
      'Full binance exchange info response is not supported',
    );
  }

  @override
  Future<BinanceExchangeInfoResponseReduced> fetchExchangeInfoReduced({
    String? baseUrl,
  }) {
    return Future.value(
      BinanceExchangeInfoResponseReduced(
        timezone: 'utc+0',
        serverTime: DateTime.now().millisecondsSinceEpoch,
        symbols: [
          SymbolReduced(
            baseAsset: 'BTC',
            quoteAsset: 'USDT',
            baseAssetPrecision: 8,
            quotePrecision: 8,
            status: 'TRADING',
            isSpotTradingAllowed: true,
            quoteAssetPrecision: 8,
            symbol: 'BTCUSDT',
          ),
          SymbolReduced(
            baseAsset: 'ETH',
            quoteAsset: 'USDT',
            baseAssetPrecision: 8,
            quotePrecision: 8,
            status: 'TRADING',
            isSpotTradingAllowed: true,
            quoteAssetPrecision: 8,
            symbol: 'ETHUSDT',
          ),
          SymbolReduced(
            baseAsset: 'KMD',
            quoteAsset: 'USDT',
            baseAssetPrecision: 8,
            quotePrecision: 8,
            status: 'TRADING',
            isSpotTradingAllowed: true,
            quoteAssetPrecision: 8,
            symbol: 'KMDUSDT',
          ),
          SymbolReduced(
            baseAsset: 'LTC',
            quoteAsset: 'USDT',
            baseAssetPrecision: 8,
            quotePrecision: 8,
            status: 'TRADING',
            isSpotTradingAllowed: true,
            quoteAssetPrecision: 8,
            symbol: 'LTCUSDT',
          ),
        ],
      ),
    );
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
    List<Ohlc> ohlc = [
      const Ohlc(
        openTime: 1708646400000,
        open: 50740.50,
        high: 50740.50,
        low: 50740.50,
        close: 50740.50,
        closeTime: 1708646400000,
      ),
      const Ohlc(
        openTime: 1708984800000,
        open: 50740.50,
        high: 50740.50,
        low: 50740.50,
        close: 50740.50,
        closeTime: 1708984800000,
      ),
      const Ohlc(
        openTime: 1714435200000,
        open: 60666.60,
        high: 60666.60,
        low: 60666.60,
        close: 60666.60,
        closeTime: 1714435200000,
      ),
      Ohlc(
        openTime: DateTime.now()
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
        open: 60666.60,
        high: 60666.60,
        low: 60666.60,
        close: 60666.60,
        closeTime: DateTime.now()
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
      ),
      Ohlc(
        openTime: DateTime.now().millisecondsSinceEpoch,
        open: 60666.60,
        high: 60666.60,
        low: 60666.60,
        close: 60666.60,
        closeTime: DateTime.now().millisecondsSinceEpoch,
      ),
      Ohlc(
        openTime:
            DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
        open: 60666.60,
        high: 60666.60,
        low: 60666.60,
        close: 60666.60,
        closeTime:
            DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      ),
    ];

    if (startUnixTimestampMilliseconds != null) {
      ohlc = ohlc
          .where((ohlc) => ohlc.closeTime >= startUnixTimestampMilliseconds)
          .toList();
    }

    if (endUnixTimestampMilliseconds != null) {
      ohlc = ohlc
          .where((ohlc) => ohlc.closeTime <= endUnixTimestampMilliseconds)
          .toList();
    }

    if (limit != null && limit > 0) {
      ohlc = ohlc.take(limit).toList();
    }

    ohlc.sort((a, b) => a.closeTime.compareTo(b.closeTime));

    return Future.value(
      CoinOhlc(
        ohlc: ohlc,
      ),
    );
  }
}
