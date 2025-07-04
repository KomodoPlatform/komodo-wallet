import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/market_maker_order_list_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/trade_pair.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/trading_entities_filter.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/shared/ui/ui_light_button.dart';
import 'package:web_dex/views/market_maker_bot/animated_bot_status_indicator.dart';
import 'package:web_dex/views/market_maker_bot/market_maker_bot_order_list_header.dart';
import 'package:web_dex/views/market_maker_bot/trade_pair_list_item.dart';

class MarketMakerBotOrdersList extends StatefulWidget {
  const MarketMakerBotOrdersList({
    required this.entitiesFilterData,
    super.key,
    this.onEdit,
    this.onCancel,
    this.onCancelAll,
  });

  final TradingEntitiesFilter? entitiesFilterData;
  final void Function(TradePair)? onEdit;
  final void Function(TradePair)? onCancel;
  final void Function(List<TradePair>)? onCancelAll;

  @override
  State<MarketMakerBotOrdersList> createState() =>
      _MarketMakerBotOrdersListState();
}

class _MarketMakerBotOrdersListState extends State<MarketMakerBotOrdersList> {
  final _mainScrollController = ScrollController();

  @override
  void initState() {
    context
        .read<MarketMakerOrderListBloc>()
        .add(const MarketMakerOrderListRequested(Duration(seconds: 3)));
    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MarketMakerBotOrdersList oldWidget) {
    if (oldWidget.entitiesFilterData != widget.entitiesFilterData) {
      context
          .read<MarketMakerOrderListBloc>()
          .add(MarketMakerOrderListFilterChanged(widget.entitiesFilterData));
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketMakerOrderListBloc, MarketMakerOrderListState>(
      builder: (context, state) {
        if (state.status == MarketMakerOrderListStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocBuilder<MarketMakerBotBloc, MarketMakerBotState>(
          builder: (context, botState) => Column(
            children: [
              if (!isMobile)
                Column(
                  children: [
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: SizedBox(height: 8),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedBotStatusIndicator(
                            status: botState.status,
                          ),
                          const SizedBox(width: 24),
                          UiPrimaryButton(
                            text: botState.isRunning
                                ? LocaleKeys.mmBotStop.tr()
                                : LocaleKeys.mmBotStart.tr(),
                            width: 120,
                            height: 32,
                            textStyle: const TextStyle(fontSize: 12),
                            onPressed: botState.isUpdating ||
                                    state.makerBotOrders.isEmpty
                                ? null
                                : botState.isRunning
                                    ? _onStopBotPressed
                                    : _onStartBotPressed,
                          ),
                          const SizedBox(width: 12),
                          UiPrimaryButton(
                            text: LocaleKeys.cancelAll.tr(),
                            width: 120,
                            height: 32,
                            textStyle: const TextStyle(fontSize: 12),
                            onPressed: botState.isUpdating ||
                                    !botState.isRunning ||
                                    state.makerBotOrders.isEmpty
                                ? null
                                : () => widget.onCancelAll
                                    ?.call(state.makerBotOrders),
                          ),
                        ],
                      ),
                    ),
                    MarketMakerBotOrderListHeader(
                      sortData: state.sortData,
                      onSortChange: _onSortChange,
                    ),
                  ],
                ),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(top: isMobile ? 0 : 10.0),
                  child: DexScrollbar(
                    isMobile: isMobile,
                    scrollController: _mainScrollController,
                    child: ListView.builder(
                      shrinkWrap: true,
                      controller: _mainScrollController,
                      itemCount: state.makerBotOrders.length,
                      itemBuilder: (BuildContext context, int index) {
                        final TradePair pair = state.makerBotOrders[index];
                        return TradePairListItem(
                          pair,
                          isBotRunning:
                              botState.isRunning || botState.isUpdating,
                          onTap: pair.order != null
                              ? () => _navigateToOrderDetails(pair)
                              : null,
                          actions: [
                            UiLightButton(
                              text: LocaleKeys.edit.tr(),
                              width: 60,
                              height: 22,
                              backgroundColor: Colors.transparent,
                              border: Border.all(
                                color: const Color.fromRGBO(234, 234, 234, 1),
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                              onPressed: botState.isUpdating
                                  ? null
                                  : () => widget.onEdit?.call(pair),
                            ),
                            UiLightButton(
                              text: LocaleKeys.cancel.tr(),
                              width: 60,
                              height: 22,
                              backgroundColor: Colors.transparent,
                              border: Border.all(
                                color: const Color.fromRGBO(234, 234, 234, 1),
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                              onPressed: botState.isUpdating
                                  ? null
                                  : () => widget.onCancel?.call(pair),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToOrderDetails(TradePair pair) {
    return routingState.marketMakerState.setDetailsAction(pair.order!.uuid);
  }

  void _onStopBotPressed() {
    context.read<MarketMakerBotBloc>().add(const MarketMakerBotStopRequested());
  }

  void _onStartBotPressed() {
    context
        .read<MarketMakerBotBloc>()
        .add(const MarketMakerBotStartRequested());
  }

  void _onSortChange(SortData<MarketMakerBotOrderListType> sortData) {
    context
        .read<MarketMakerOrderListBloc>()
        .add(MarketMakerOrderListSortChanged(sortData));
  }
}
