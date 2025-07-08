import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/shared/utils/utils.dart';

import 'models/price_chart_data.dart';
import 'price_chart_event.dart';
import 'price_chart_state.dart';

class PriceChartBloc extends Bloc<PriceChartEvent, PriceChartState> {
  PriceChartBloc(this.cexPriceRepository, this.sdk)
      : super(const PriceChartState()) {
    on<PriceChartStarted>(_onStarted);
    on<PriceChartPeriodChanged>(_onIntervalChanged);
    on<PriceChartCoinsSelected>(_onSymbolChanged);
  }

  final BinanceRepository cexPriceRepository;
  final KomodoDefiSdk sdk;
  final KomodoPriceRepository _komodoPriceRepository = KomodoPriceRepository(
    cexPriceProvider: KomodoPriceProvider(),
  );

  void _onStarted(
    PriceChartStarted event,
    Emitter<PriceChartState> emit,
  ) async {
    emit(state.copyWith(status: PriceChartStatus.loading));
    try {
      Map<AssetId, CoinPriceInfo> fetchedCexCoins = state.availableCoins;
      if (state.availableCoins.isEmpty) {
        fetchedCexCoins = await _fetchCoinsFromCex();
      }

      final List<Future<PriceChartDataSeries?>> futures = event.symbols
          .map((symbol) => sdk.getSdkAsset(symbol).id)
          .map((symbol) async {
        try {
          final CoinOhlc ohlcData = await cexPriceRepository.getCoinOhlc(
            CexCoinPair.usdtPrice(symbol.symbol.assetConfigId),
            _dividePeriodToInterval(event.period),
            startAt: DateTime.now().subtract(event.period),
            endAt: DateTime.now(),
          );

          final rangeChangePercent = _calculatePercentageChange(
            ohlcData.ohlc.firstOrNull,
            ohlcData.ohlc.lastOrNull,
          );

          return PriceChartDataSeries(
            info: CoinPriceInfo(
              ticker: symbol.symbol.assetConfigId,
              id: fetchedCexCoins[symbol]!.id,
              name: fetchedCexCoins[symbol]!.name,
              selectedPeriodIncreasePercentage: rangeChangePercent ?? 0.0,
            ),
            data: ohlcData.ohlc.map((e) {
              return PriceChartSeriesPoint(
                usdValue: e.close,
                unixTimestamp: e.closeTime.toDouble(),
              );
            }).toList(),
          );
        } catch (e) {
          log("Error fetching OHLC data for $symbol: $e");
          return null;
        }
      }).toList();

      final data = await Future.wait(futures);

      emit(
        state.copyWith(
          status: PriceChartStatus.success,
          data: data
              .where((series) => series != null)
              .cast<PriceChartDataSeries>()
              .toList(),
          selectedPeriod: event.period,
          availableCoins: fetchedCexCoins,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PriceChartStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<Map<AssetId, CoinPriceInfo>> _fetchCoinsFromCex() async {
    final coinPrices = await _komodoPriceRepository.getKomodoPrices();
    final coins = (await cexPriceRepository.getCoinList())
        .where((coin) => coin.currencies.contains('USDT'))
        // `cexPriceRepository.getCoinList()` returns coins from a CEX
        // (e.g. Binance), some of which are not in our known/available
        // assets/coins list. This filter ensures that we only attempt to
        // fetch and display data for supported coins
        .where((coin) => sdk.assets.assetsFromTicker(coin.id).isNotEmpty)
        .map((coin) async {
      double? dayChangePercent = coinPrices[coin.symbol]?.change24h;

      if (dayChangePercent == null) {
        try {
          final coinOhlc = await cexPriceRepository.getCoinOhlc(
            CexCoinPair.usdtPrice(coin.symbol),
            GraphInterval.oneMinute,
            startAt: DateTime.now().subtract(const Duration(days: 1)),
            endAt: DateTime.now(),
          );

          dayChangePercent = _calculatePercentageChange(
            coinOhlc.ohlc.firstOrNull,
            coinOhlc.ohlc.lastOrNull,
          );
        } catch (e) {
          log("Error fetching OHLC data for ${coin.symbol}: $e");
        }
      }
      return CoinPriceInfo(
        ticker: coin.symbol,
        id: coin.id,
        name: coin.name,
        selectedPeriodIncreasePercentage: dayChangePercent ?? 0.0,
      );
    }).toList();

    final fetchedCexCoins = {
      for (var coin in await Future.wait(coins))
        sdk.getSdkAsset(coin.ticker).id: coin,
    };

    return fetchedCexCoins;
  }

  double? _calculatePercentageChange(Ohlc? first, Ohlc? last) {
    if (first == null || last == null) {
      return null;
    }

    // Calculate the typical price for the first and last OHLC entries
    final firstTypicalPrice =
        (first.open + first.high + first.low + first.close) / 4;
    final lastTypicalPrice =
        (last.open + last.high + last.low + last.close) / 4;

    if (firstTypicalPrice == 0) {
      return null;
    }

    return ((lastTypicalPrice - firstTypicalPrice) / firstTypicalPrice) * 100;
  }

  void _onIntervalChanged(
    PriceChartPeriodChanged event,
    Emitter<PriceChartState> emit,
  ) {
    final currentState = state;
    if (currentState.status != PriceChartStatus.success) {
      return;
    }
    emit(
      state.copyWith(
        selectedPeriod: event.period,
      ),
    );
    add(
      PriceChartStarted(
        symbols: currentState.data.map((e) => e.info.id).toList(),
        period: event.period,
      ),
    );
  }

  void _onSymbolChanged(
    PriceChartCoinsSelected event,
    Emitter<PriceChartState> emit,
  ) {
    add(
      PriceChartStarted(
        symbols: event.symbols,
        period: state.selectedPeriod,
      ),
    );
  }

  GraphInterval _dividePeriodToInterval(Duration period) {
    if (period.inDays >= 365) {
      return GraphInterval.oneWeek;
    }
    if (period.inDays >= 30) {
      return GraphInterval.oneDay;
    }
    if (period.inDays >= 7) {
      return GraphInterval.sixHours;
    }
    if (period.inDays >= 1) {
      return GraphInterval.oneHour;
    }
    if (period.inHours >= 1) {
      return GraphInterval.oneMinute;
    }

    throw Exception('Unknown interval');
  }
}
