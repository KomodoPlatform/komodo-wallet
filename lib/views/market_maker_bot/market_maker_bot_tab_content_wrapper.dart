import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/trade_pair.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_trade_form/market_maker_trade_form_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/model/trading_entities_filter.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/views/dex/dex_list_filter/desktop/dex_list_filter_desktop.dart';
import 'package:web_dex/views/dex/dex_list_filter/mobile/dex_list_filter_mobile.dart';
import 'package:web_dex/views/dex/dex_list_filter/mobile/dex_list_header_mobile.dart';
import 'package:web_dex/views/dex/entities_list/history/history_list.dart';
import 'package:web_dex/views/dex/entities_list/in_progress/in_progress_list.dart';
import 'package:web_dex/views/market_maker_bot/market_maker_bot_form.dart';
import 'package:web_dex/views/market_maker_bot/market_maker_bot_order_list.dart';
import 'package:web_dex/views/market_maker_bot/market_maker_bot_tab_type.dart';

class MarketMakerBotTabContentWrapper extends StatefulWidget {
  const MarketMakerBotTabContentWrapper(
    this.listType, {
    this.filter,
    super.key,
  });

  final MarketMakerBotTabType listType;
  final TradingEntitiesFilter? filter;

  @override
  State<MarketMakerBotTabContentWrapper> createState() =>
      _MarketMakerBotTabContentWrapperState();
}

class _MarketMakerBotTabContentWrapperState
    extends State<MarketMakerBotTabContentWrapper> {
  bool _isFilterShown = false;
  MarketMakerBotTabType? previouseType;

  @override
  Widget build(BuildContext context) {
    previouseType ??= widget.listType;
    if (previouseType != widget.listType) {
      _isFilterShown = false;
      previouseType = widget.listType;
    }
    final child = _SelectedTabContent(
      key: Key('dex-list-${widget.listType}'),
      filter: widget.filter,
      type: widget.listType,
    );

    // the reason why the widgets need to prop drill all filter data,
    // is because the widget wraps a table with filters and a dex/market
    // maker widget. Widget type = enum value at current tab index
    return isMobile
        ? _MobileWidget(
            key: const Key('dex-list-wrapper-mobile'),
            type: widget.listType,
            filterData: widget.filter,
            onApplyFilter: _setFilter,
            isFilterShown: _isFilterShown,
            onFilterTap: () => setState(() {
              _isFilterShown = !_isFilterShown;
            }),
            child: child,
          )
        : _DesktopWidget(
            key: const Key('dex-list-wrapper-desktop'),
            type: widget.listType,
            filterData: widget.filter,
            onApplyFilter: _setFilter,
            child: child,
          );
  }

  void _setFilter(TradingEntitiesFilter? filter) {
    context.read<DexTabBarBloc>().add(
          FilterChanged(
            tabType: widget.listType,
            filter: filter,
          ),
        );
  }
}

class _SelectedTabContent extends StatelessWidget {
  const _SelectedTabContent({
    this.filter,
    required this.type,
    super.key,
  });

  // TODO: get the current filter and type from BLoC state
  final TradingEntitiesFilter? filter;
  final MarketMakerBotTabType type;

  @override
  Widget build(BuildContext context) {
    final marketMakerBotBloc = context.read<MarketMakerBotBloc>();

    switch (type) {
      case MarketMakerBotTabType.orders:
        return MarketMakerBotOrdersList(
          entitiesFilterData: filter,
          onEdit: (order) => _editTradingBotOrder(context, order),
          onCancel: (order) => _deleteTradingBotOrders(
            [order],
            marketMakerBotBloc,
          ),
          onCancelAll: (orders) {
            _deleteTradingBotOrders(orders, marketMakerBotBloc);
          },
        );
      case MarketMakerBotTabType.inProgress:
        return InProgressList(
          entitiesFilterData: filter,
          onItemClick: _onSwapItemClick,
        );
      case MarketMakerBotTabType.history:
        return HistoryList(
          entitiesFilterData: filter,
          onItemClick: _onSwapItemClick,
        );
      case MarketMakerBotTabType.marketMaker:
        return const MarketMakerBotForm();
    }
  }

  /// Cancels the existing order, updates the trading pairs in the settings
  /// and updates the market maker bot.
  ///
  /// [tradePair] the order to delete
  /// [marketMakerBotBloc] the market maker bot bloc
  void _deleteTradingBotOrders(
    Iterable<TradePair> tradePair,
    MarketMakerBotBloc marketMakerBotBloc,
  ) {
    final tradePairs = tradePair.map((e) => e.config).toList();
    marketMakerBotBloc.add(MarketMakerBotOrderCancelRequested(tradePairs));
  }

  void _editTradingBotOrder(BuildContext context, TradePair order) {
    context
        .read<MarketMakerTradeFormBloc>()
        .add(MarketMakerTradeFormEditOrderRequested(order));
    context.read<DexTabBarBloc>().add(const TabChanged(0));
  }

  void _onSwapItemClick(Swap swap) {
    routingState.marketMakerState.setDetailsAction(swap.uuid);
  }
}

class _MobileWidget extends StatelessWidget {
  final MarketMakerBotTabType type;
  final Widget child;
  final TradingEntitiesFilter? filterData;
  final bool isFilterShown;
  final VoidCallback onFilterTap;
  final void Function(TradingEntitiesFilter?) onApplyFilter;

  const _MobileWidget({
    required this.type,
    required this.child,
    required this.onApplyFilter,
    this.filterData,
    required this.isFilterShown,
    required this.onFilterTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (type == MarketMakerBotTabType.marketMaker) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: child,
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DexListHeaderMobile(
            entitiesFilterData: filterData,
            listType: type.toDexListType(),
            isFilterShown: isFilterShown,
            onFilterDataChange: onApplyFilter,
            onFilterPressed: onFilterTap,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: isFilterShown
                ? DexListFilterMobile(
                    filterData: filterData,
                    onApplyFilter: onApplyFilter,
                    listType: type.toDexListType(),
                  )
                : child,
          ),
        ],
      );
    }
  }
}

class _DesktopWidget extends StatelessWidget {
  final MarketMakerBotTabType type;
  final Widget child;
  final TradingEntitiesFilter? filterData;
  final void Function(TradingEntitiesFilter?) onApplyFilter;
  const _DesktopWidget({
    required this.type,
    required this.child,
    required this.filterData,
    required this.onApplyFilter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (type == MarketMakerBotTabType.marketMaker) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(child: child),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DexListFilterDesktop(
            filterData: filterData,
            onApplyFilter: onApplyFilter,
            listType: type.toDexListType(),
          ),
          Flexible(child: child),
        ],
      );
    }
  }
}
