import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/bridge_form/bridge_bloc.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_repo.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/views/bridge/bridge_protocol_label.dart';
import 'package:komodo_wallet/views/bridge/pick_item.dart';

class BridgeTargetProtocolSelectorTile extends StatefulWidget {
  const BridgeTargetProtocolSelectorTile({
    Key? key,
    this.coin,
    this.bestOrder,
    this.disabled = false,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  final Coin? coin;
  final BestOrder? bestOrder;
  final bool disabled;
  final String title;
  final Function() onTap;

  @override
  State<BridgeTargetProtocolSelectorTile> createState() =>
      _BridgeTargetProtocolSelectorTileState();
}

class _BridgeTargetProtocolSelectorTileState
    extends State<BridgeTargetProtocolSelectorTile> {
  bool get noSelected => widget.coin == null && widget.bestOrder == null;

  Coin? get coin {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    final widgetCoin = widget.coin;
    if (widgetCoin != null) return widgetCoin;
    final bestOrder = widget.bestOrder;
    if (bestOrder != null) return coinsRepository.getCoin(bestOrder.coin);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return noSelected
        ? PickItem(
            title: widget.title,
            onTap: widget.disabled ? null : widget.onTap,
            expanded: context.read<BridgeBloc>().state.showTargetDropdown,
          )
        : _SelectedProtocolTile(
            coin: coin!,
            onTap: widget.onTap,
          );
  }
}

class _SelectedProtocolTile extends StatelessWidget {
  const _SelectedProtocolTile({
    Key? key,
    required this.coin,
    required this.onTap,
  }) : super(key: key);

  final Coin coin;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        hoverColor: theme.custom.noColor,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BridgeProtocolLabel(coin),
            const SizedBox(width: 6),
            Icon(
                context.read<BridgeBloc>().state.showTargetDropdown
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: Theme.of(context).textTheme.bodyLarge?.color),
          ],
        ),
      ),
    );
  }
}
