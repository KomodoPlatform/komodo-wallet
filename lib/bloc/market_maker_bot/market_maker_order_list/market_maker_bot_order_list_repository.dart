import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/trade_pair.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/trade_coin_pair_config.dart';
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
    final makerOrders = (await _ordersService.getOrders())
        ?.where((order) => order.orderType == TradeSide.maker);

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
    return order?.baseAmountAvailable ??
        _getBaseAmountFromVolume(config.baseCoinId, config.maxVolume!.value);
  }

  Rational _getBaseAmountFromVolume(String baseCoinId, double maxVolume) {
    final baseCoin = _coinsRepository.getCoin(baseCoinId);
    final baseCoinBalance = baseCoin == null
        ? Decimal.zero
        : _coinsRepository.lastKnownBalance(baseCoin.id)?.spendable ??
            Decimal.zero;
    return baseCoinBalance.toRational() *
        Rational.parse(baseCoinBalance.toString());
  }

  Rational _getRelAmountFromBaseAmount(
    Rational baseCoinAmount,
    TradeCoinPairConfig config,
    MyOrder? order,
  ) {
    final double? baseUsdPrice =
        _coinsRepository.getCoin(config.baseCoinId)?.usdPrice?.price;
    final double? relUsdPrice =
        _coinsRepository.getCoin(config.relCoinId)?.usdPrice?.price;
    final price = relUsdPrice != null && baseUsdPrice != null
        ? baseUsdPrice / relUsdPrice
        : null;

    Rational relAmount = Rational.zero;
    if (price != null) {
      final double priceWithMargin = price * (1 + (config.margin / 100));
      final double amount = baseCoinAmount.toDouble() * priceWithMargin;
      return Rational.parse(amount.toString());
    }

    return relAmount;
  }
}
