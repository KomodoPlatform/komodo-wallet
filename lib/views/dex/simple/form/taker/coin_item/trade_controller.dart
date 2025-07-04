import 'package:flutter/material.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:komodo_wallet/model/coin.dart';

abstract class TradeController {
  TradeController({
    required this.coin,
    required this.onTap,
    required this.isOpened,
    required this.isEnabled,
  });

  final Coin? coin;
  final GestureTapCallback? onTap;
  final bool isOpened;
  final bool isEnabled;
}

class TradeCoinController extends TradeController {
  TradeCoinController({
    required super.coin,
    required super.onTap,
    required super.isOpened,
    required super.isEnabled,
  });
}

class TradeOrderController extends TradeController {
  TradeOrderController({
    required super.coin,
    required this.order,
    required super.onTap,
    required super.isOpened,
    required super.isEnabled,
  });

  final BestOrder? order;
}
