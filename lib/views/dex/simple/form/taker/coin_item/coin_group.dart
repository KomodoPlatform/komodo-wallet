import 'package:flutter/material.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_logo.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/coin_name_and_protocol.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class CoinGroup extends StatelessWidget {
  const CoinGroup(this.controller, {Key? key}) : super(key: key);

  final TradeController controller;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: controller.onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoinLogo(coin: controller.coin),
            const SizedBox(width: 9),
            CoinNameAndProtocol(controller.coin, controller.isOpened),
            const SizedBox(width: 9),
          ],
        ),
      ),
    );
  }
}
