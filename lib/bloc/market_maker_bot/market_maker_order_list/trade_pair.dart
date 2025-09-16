import 'package:rational/rational.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/trade_coin_pair_config.dart';
import 'package:web_dex/model/my_orders/my_order.dart';

class TradePair {
  TradePair(
    this.config,
    this.order, {
    Rational? baseCoinAmount,
    Rational? relCoinAmount,
  }) : baseCoinAmount = baseCoinAmount ?? Rational.zero,
       relCoinAmount = relCoinAmount ?? Rational.zero;

  final TradeCoinPairConfig config;
  final MyOrder? order;

  // needed to show coin amounts instead of 0 in the order list table before
  // the order is created
  final Rational baseCoinAmount;
  final Rational relCoinAmount;

  MyOrder get orderPreview => MyOrder(
    base: config.baseCoinId,
    rel: config.relCoinId,
    baseAmount: Rational.zero,
    relAmount: Rational.zero,
    cancelable: false,
    createdAt: DateTime.now().millisecondsSinceEpoch,
    uuid: '',
    orderType: TradeSide.maker,
  );

  TradePair copyWith({TradeCoinPairConfig? config, MyOrder? order}) {
    return TradePair(config ?? this.config, order ?? this.order);
  }
}
