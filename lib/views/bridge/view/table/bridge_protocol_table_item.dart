import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';
import 'package:komodo_wallet/views/bridge/bridge_protocol_label.dart';

class BridgeProtocolTableItem extends StatelessWidget {
  const BridgeProtocolTableItem({
    super.key,
    required this.coin,
    required this.onSelect,
    required this.index,
  });

  final Coin coin;
  final Function onSelect;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double? balance = coin.isActive
        ? context.sdk.balances.lastKnown(coin.id)?.spendable.toDouble() ?? 0.0
        : null;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: Key('bridge-protocol-table-item-${coin.abbr}-$index'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => onSelect(),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              BridgeProtocolLabel(coin),
              const Expanded(
                child: SizedBox(),
              ),
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
