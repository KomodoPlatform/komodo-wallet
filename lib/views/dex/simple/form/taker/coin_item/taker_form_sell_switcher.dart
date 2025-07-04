import 'package:flutter/material.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/coin_group.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/taker_form_sell_amount.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class TakerFormSellSwitcher extends StatelessWidget {
  const TakerFormSellSwitcher({
    required this.controller,
    this.padding = const EdgeInsets.only(top: 16, bottom: 12),
  });

  final TradeCoinController controller;
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
              CoinGroup(controller, key: const Key('taker-form-sell-switcher')),
              const SizedBox(width: 5),
              Expanded(child: TakerFormSellAmount(controller.isEnabled)),
            ],
          ),
        ),
      ],
    );
  }
}
