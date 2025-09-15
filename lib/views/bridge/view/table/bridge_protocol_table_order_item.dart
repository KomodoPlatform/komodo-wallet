import 'package:flutter/material.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/bridge/bridge_protocol_label.dart';

class BridgeProtocolTableOrderItem extends StatelessWidget {
  const BridgeProtocolTableOrderItem({
    super.key,
    required this.order,
    required this.coin,
    required this.onSelect,
    required this.index,
  });

  final BestOrder order;
  final Coin coin;
  final Function onSelect;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double? balance = coin.isActive
        ? context.sdk.balances.lastKnown(coin.id)?.spendable.toDouble() ?? 0.0
        : null;

    log('BridgeProtocolTableOrderItem.build([context]) $balance');

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: Key('bridge-protocol-table-item-${order.coin}-$index'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => onSelect(),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              BridgeProtocolLabel(coin),
              const Expanded(child: SizedBox()),
              Text(
                formatDexAmt(balance),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
