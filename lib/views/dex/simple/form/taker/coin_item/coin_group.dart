import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/coin_name_and_protocol.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/trade_controller.dart';

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
            controller.coin == null
                // Use the legacy blank placeholder rather than the
                // default monetised icon placeholder
                ? AssetLogo.placeholder(isBlank: true)
                : AssetLogo.ofId(controller.coin!.id),
            const SizedBox(width: 9),
            CoinNameAndProtocol(controller.coin, controller.isOpened),
            const SizedBox(width: 9),
          ],
        ),
      ),
    );
  }
}
