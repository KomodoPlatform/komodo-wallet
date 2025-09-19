import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/bridge/bridge_protocol_label.dart';
import 'package:web_dex/views/bridge/pick_item.dart';

class BridgeSourceProtocolSelectorTile extends StatefulWidget {
  const BridgeSourceProtocolSelectorTile(
      {Key? key, this.coin, required this.title, required this.onTap})
      : super(key: key);

  final Coin? coin;
  final String title;
  final Function() onTap;

  @override
  State<BridgeSourceProtocolSelectorTile> createState() =>
      _BridgeSourceProtocolSelectorTileState();
}

class _BridgeSourceProtocolSelectorTileState
    extends State<BridgeSourceProtocolSelectorTile> {
  @override
  Widget build(BuildContext context) {
    final Coin? coin = widget.coin;

    return BlocSelector<BridgeBloc, BridgeState, bool>(
        selector: (state) => state.showSourceDropdown,
        builder: (context, expanded) {
          return SizedBox(
            height: 24,
            child: coin == null
                ? PickItem(
                    title: widget.title,
                    onTap: widget.onTap,
                    expanded: expanded,
                  )
                : _SelectedProtocolTile(
                    coin: coin,
                    onTap: widget.onTap,
                    expanded: expanded,
                  ),
          );
        });
  }
}

class _SelectedProtocolTile extends StatelessWidget {
  const _SelectedProtocolTile({
    Key? key,
    required this.coin,
    required this.expanded,
    required this.onTap,
  }) : super(key: key);

  final Coin coin;
  final bool expanded;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        hoverColor: theme.custom.noColor,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BridgeProtocolLabel(coin),
            const SizedBox(width: 6),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ],
        ),
      ),
    );
  }
}
