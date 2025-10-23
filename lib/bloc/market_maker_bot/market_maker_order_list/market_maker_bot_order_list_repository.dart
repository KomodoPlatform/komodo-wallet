import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/trade_pair.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/trade_coin_pair_config.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/trade_volume.dart';
import 'package:web_dex/views/market_maker_bot/trade_volume_type.dart';
import 'package:web_dex/model/my_orders/my_order.dart';
import 'package:web_dex/services/orders_service/my_orders_service.dart';

class MarketMakerBotOrderListRepository {
  const MarketMakerBotOrderListRepository(
    this._ordersService,
    this._settingsRepository,
    this._coinsRepository,
  );

  final CoinsRepo _coinsRepository;
  final MyOrdersService _ordersService;
  final SettingsRepository _settingsRepository;

  Future<void> cancelOrders(List<TradeCoinPairConfig> tradePairs) async {
    final orders = await _ordersService.getOrders();
    final ordersToCancel = orders
        ?.where(
          (order) =>
              tradePairs.any(
                (tradePair) =>
                    order.base == tradePair.baseCoinId &&
                    order.rel == tradePair.relCoinId,
              ) &&
              order.orderType == TradeSide.maker,
        )
        .toList();

    if (ordersToCancel?.isEmpty ?? false) {
      return;
    }

    for (final order in ordersToCancel!) {
      await _ordersService.cancelOrder(order.uuid);
    }
  }

  Future<List<TradePair>> getTradePairs() async {
    final settings = await _settingsRepository.loadSettings();
    final configs = settings.marketMakerBotSettings.tradeCoinPairConfigs;
    final makerOrders = (await _ordersService.getOrders())?.where(
      (order) => order.orderType == TradeSide.maker,
    );

    final tradePairs = configs.map((TradeCoinPairConfig config) {
      final order = makerOrders
          ?.where(
            (order) =>
                order.base == config.baseCoinId &&
                order.rel == config.relCoinId,
          )
          .firstOrNull;

      final Rational baseCoinAmount = _getBaseCoinAmount(config, order);
      return TradePair(
        config,
        order,
        baseCoinAmount: baseCoinAmount,
        relCoinAmount: _getRelCoinAmount(baseCoinAmount, config, order),
      );
    }).toList();

    return tradePairs;
  }

  Rational _getRelCoinAmount(
    Rational baseCoinAmount,
    TradeCoinPairConfig config,
    MyOrder? order,
  ) {
    return order?.relAmountAvailable ??
        _getRelAmountFromBaseAmount(baseCoinAmount, config, order);
  }

  Rational _getBaseCoinAmount(TradeCoinPairConfig config, MyOrder? order) {
    if (order?.baseAmountAvailable != null) {
      return order!.baseAmountAvailable!;
    }

    final TradeVolume? maxVolume = config.maxVolume;
    if (maxVolume == null) return Rational.zero;

    return _getBaseAmountFromVolume(config.baseCoinId, maxVolume);
  }

  Rational _getBaseAmountFromVolume(String baseCoinId, TradeVolume maxVolume) {
    final baseCoin = _coinsRepository.getCoin(baseCoinId);
    final Decimal balance = baseCoin == null
        ? Decimal.zero
        : _coinsRepository.lastKnownBalance(baseCoin.id)?.spendable ??
            Decimal.zero;

    if (balance == Decimal.zero) return Rational.zero;

    final Rational balanceRational = balance.toRational();

    if (maxVolume.type == TradeVolumeType.percentage) {
      // maxVolume.value is a fraction (e.g., 0.1 for 10%)
      final Rational percentage = Rational.parse(maxVolume.value.toString());
      final Rational desired = balanceRational * percentage;
      return desired > balanceRational ? balanceRational : desired;
    }

    // USD-based volume: convert USD to base coin amount using USD price (as Rational), then clamp to balance
    final Decimal? usdPrice = baseCoin?.usdPrice?.price;
    if (usdPrice == null || usdPrice == Decimal.zero) return Rational.zero;

    final Rational usdPriceRational = usdPrice.toRational();
    final Rational usdVolumeRational =
        Rational.parse(maxVolume.value.toString());
    final Rational amountInBase = usdVolumeRational / usdPriceRational;
    return amountInBase > balanceRational ? balanceRational : amountInBase;
  }

  Rational _getRelAmountFromBaseAmount(
    Rational baseCoinAmount,
    TradeCoinPairConfig config,
    MyOrder? order,
  ) {
    final Decimal? baseUsdPrice = _coinsRepository
        .getCoin(config.baseCoinId)
        ?.usdPrice
        ?.price;
    final Decimal? relUsdPrice = _coinsRepository
        .getCoin(config.relCoinId)
        ?.usdPrice
        ?.price;
    final price = relUsdPrice != null && baseUsdPrice != null
        ? baseUsdPrice / relUsdPrice
        : null;

    Rational relAmount = Rational.zero;
    if (price != null) {
      final Rational marginFraction =
          Decimal.parse(config.margin.toString()) / Decimal.fromInt(100);
      final Rational priceWithMargin = price * (Rational.one + marginFraction);
      return baseCoinAmount * priceWithMargin;
    }

    return relAmount;
  }
}
