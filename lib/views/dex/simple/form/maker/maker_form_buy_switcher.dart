import 'package:flutter/material.dart';
import 'package:web_dex/views/dex/simple/form/maker/maker_form_buy_amount.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/coin_group.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class MakerFormBuySwitcher extends StatelessWidget {
  const MakerFormBuySwitcher({required this.controller, Key? key})
    : super(key: key);

  final TradeCoinController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CoinGroup(controller, key: const Key('maker-form-buy-switcher')),
            const SizedBox(width: 5),
            Expanded(child: MakerFormBuyAmount(controller.isEnabled)),
          ],
        ),
      ],
    );
  }
}
