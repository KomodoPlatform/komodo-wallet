import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/typedef.dart';
import 'package:web_dex/views/bridge/bridge_exchange_form.dart';
import 'package:web_dex/views/bridge/bridge_group.dart';
import 'package:web_dex/views/bridge/view/table/bridge_nothing_found.dart';
import 'package:web_dex/views/bridge/view/table/bridge_protocol_table_item.dart';
import 'package:web_dex/views/bridge/view/table/bridge_table_column_heads.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';

class BridgeSourceProtocolsTable extends StatefulWidget {
  const BridgeSourceProtocolsTable({
    required this.onSelect,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  final Function(Coin) onSelect;
  final GestureTapCallback onClose;

  @override
  State<BridgeSourceProtocolsTable> createState() =>
      _BridgeSourceProtocolsTableState();
}

class _BridgeSourceProtocolsTableState
    extends State<BridgeSourceProtocolsTable> {
  @override
  Widget build(BuildContext context) {
    return BridgeGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SourceProtocol(),
          const Divider(),
          Flexible(
            child: BlocBuilder<BridgeBloc, BridgeState>(
              buildWhen: (prev, cur) {
                return prev.selectedTicker != cur.selectedTicker ||
                    prev.sellCoins != cur.sellCoins;
              },
              builder: (context, state) {
                final CoinsByTicker? sellCoins = state.sellCoins;
                if (sellCoins == null) return const UiSpinnerList();
                if (sellCoins.isEmpty) return BridgeNothingFound();

                final ticker = state.selectedTicker;
                if (ticker == null) return BridgeNothingFound();

                final List<Coin>? coins = sellCoins[ticker];
                if (coins == null || coins.isEmpty) {
                  return BridgeNothingFound();
                }

                return _SourceProtocolItems(
                  key: const Key('source-protocols-items'),
                  coins: coins,
                  onSelect: widget.onSelect,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceProtocolItems extends StatelessWidget {
  const _SourceProtocolItems({
    super.key,
    required this.coins,
    required this.onSelect,
  });

  final List<Coin> coins;
  final Function(Coin) onSelect;

  @override
  Widget build(BuildContext context) {
    final tradingState = context.watch<TradingStatusBloc>().state;
    final filteredCoins = coins
        .where((coin) => tradingState.canTradeAssets([coin.id]))
        .toList();
    if (filteredCoins.isEmpty) return BridgeNothingFound();
    final scrollController = ScrollController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BridgeTableColumnHeads(),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: DexScrollbar(
              isMobile: isMobile,
              scrollController: scrollController,
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: filteredCoins.length,
                itemBuilder: (BuildContext context, int index) {
                  final Coin coin = filteredCoins[index];

                  return BridgeProtocolTableItem(
                    index: index,
                    coin: coin,
                    onSelect: () => onSelect(coin),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
