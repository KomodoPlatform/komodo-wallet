import 'package:flutter/material.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/coin_group.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/taker_form_buy_amount.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class TakerFormBuySwitcher extends StatelessWidget {
  const TakerFormBuySwitcher(
    this.controller, {
    this.padding = const EdgeInsets.only(top: 16, bottom: 14),
  });

  final TradeOrderController controller;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoinGroup(controller, key: const Key('taker-form-buy-switcher')),
              const SizedBox(width: 5),
              Expanded(child: TakerFormBuyAmount(controller.isEnabled)),
            ],
          ),
        ),
      ],
    );
  }
}
