import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/bridge/bridge_exchange_form.dart';
import 'package:web_dex/views/bridge/bridge_group.dart';
import 'package:web_dex/views/bridge/view/table/bridge_nothing_found.dart';
import 'package:web_dex/views/bridge/view/table/bridge_protocol_table_order_item.dart';
import 'package:web_dex/views/bridge/view/table/bridge_table_column_heads.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';

class BridgeTargetProtocolsTable extends StatefulWidget {
  const BridgeTargetProtocolsTable({
    required this.onSelect,
    required this.onClose,
    this.multiProtocol = false,
    Key? key,
  }) : super(key: key);

  final Function(BestOrder) onSelect;
  final GestureTapCallback onClose;
  final bool multiProtocol;

  @override
  State<BridgeTargetProtocolsTable> createState() =>
      _BridgeTargetProtocolsTableState();
}

class _BridgeTargetProtocolsTableState
    extends State<BridgeTargetProtocolsTable> {
  @override
  void initState() {
    _update(silent: true);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BridgeGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const TargetProtocol(),
          const Divider(),
          Flexible(
            child: BlocSelector<BridgeBloc, BridgeState, BestOrders?>(
              selector: (state) => state.bestOrders,
              builder: (context, bestOrders) {
                if (bestOrders == null) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(0, 30, 0, 10),
                    alignment: const Alignment(0, 0),
                    child: const UiSpinner(),
                  );
                }

                final BaseError? error = bestOrders.error;
                if (error != null) {
                  return _TargetProtocolErrorMessage(
                    key: const Key('target-protocols-error'),
                    error: error,
                    onRetry: () => _update(silent: false),
                  );
                }

                final Map<String, List<BestOrder>> orders = bestOrders.result!;
                return _TargetProtocolItems(
                  key: const Key('target-protocols-items'),
                  bestOrders: orders,
                  onSelect: widget.onSelect,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _update({required bool silent}) {
    context.read<BridgeBloc>().add(BridgeUpdateBestOrders(silent: silent));
  }
}

class _TargetProtocolItems extends StatelessWidget {
  const _TargetProtocolItems({
    super.key,
    required this.bestOrders,
    required this.onSelect,
  });

  final Map<String, List<BestOrder>> bestOrders;
  final Function(BestOrder) onSelect;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BridgeBloc>();
    final sellCoin = bloc.state.sellCoin;
    if (sellCoin == null) return BridgeNothingFound();

    final targetsList = bloc.prepareTargetsList(bestOrders);
    if (targetsList.isEmpty) return BridgeNothingFound();

    final scrollController = ScrollController();
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);

    final tradingState = context.watch<TradingStatusBloc>().state;
    final filteredTargets = targetsList.where((order) {
      final Coin? coin = coinsRepository.getCoin(order.coin);
      if (coin == null) return false;
      return tradingState.canTradeAssets([sellCoin.id, coin.id]);
    }).toList();

    if (filteredTargets.isEmpty) return BridgeNothingFound();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BridgeTableColumnHeads(),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: DexScrollbar(
              scrollController: scrollController,
              isMobile: isMobile,
              child: ListView.builder(
                controller: scrollController,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  final BestOrder order = filteredTargets[index];
                  final Coin coin = coinsRepository.getCoin(order.coin)!;

                  return BridgeProtocolTableOrderItem(
                    index: index,
                    coin: coin,
                    order: order,
                    onSelect: () => onSelect(order),
                  );
                },
                itemCount: filteredTargets.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TargetProtocolErrorMessage extends StatelessWidget {
  const _TargetProtocolErrorMessage({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final BaseError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 30, 12, 10),
      alignment: const Alignment(0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Flexible(
                child: SelectableText(
                  error.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 4),
              UiSimpleButton(
                onPressed: onRetry,
                child: Text(
                  LocaleKeys.retryButtonText.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
