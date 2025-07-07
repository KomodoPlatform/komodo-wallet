import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/dex_list_type.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/model/trading_entities_filter.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/views/dex/dex_list_filter/desktop/dex_list_filter_desktop.dart';
import 'package:web_dex/views/dex/dex_list_filter/mobile/dex_list_filter_mobile.dart';
import 'package:web_dex/views/dex/dex_list_filter/mobile/dex_list_header_mobile.dart';
import 'package:web_dex/views/dex/entities_list/history/history_list.dart';
import 'package:web_dex/views/dex/entities_list/in_progress/in_progress_list.dart';
import 'package:web_dex/views/dex/entities_list/orders/orders_list.dart';
import 'package:web_dex/views/dex/simple/form/taker/taker_form.dart';

class DexListWrapper extends StatefulWidget {
  const DexListWrapper(this.listType, {super.key});
  final DexListType listType;

  @override
  State<DexListWrapper> createState() => _DexListWrapperState();
}

class _DexListWrapperState extends State<DexListWrapper> {
  final filters = <DexListType, TradingEntitiesFilter?>{
    DexListType.swap: null,
    DexListType.orders: null,
    DexListType.inProgress: null,
    DexListType.history: null,
  };
  bool _isFilterShown = false;
  DexListType? previouseType;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = filters[widget.listType];
    previouseType ??= widget.listType;
    if (previouseType != widget.listType) {
      _isFilterShown = false;
      previouseType = widget.listType;
    }
    final child = _DexListWidget(
      key: Key('dex-list-${widget.listType}'),
      filter: filter,
      type: widget.listType,
      onSwapItemClick: _onSwapItemClick,
    );
    return isMobile
        ? _MobileWidget(
            key: const Key('dex-list-wrapper-mobile'),
            type: widget.listType,
            filterData: filter,
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
            filterData: filter,
            onApplyFilter: _setFilter,
            child: child,
          );
  }

  void _setFilter(TradingEntitiesFilter? filter) {
    setState(() {
      filters[widget.listType] = filter;
    });
  }

  void _onSwapItemClick(Swap swap) {
    routingState.dexState.setDetailsAction(swap.uuid);
  }
}

class _DexListWidget extends StatelessWidget {
  final TradingEntitiesFilter? filter;
  final DexListType type;
  final void Function(Swap) onSwapItemClick;
  const _DexListWidget({
    this.filter,
    required this.type,
    required this.onSwapItemClick,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case DexListType.orders:
        return OrdersList(
          entitiesFilterData: filter,
        );
      case DexListType.inProgress:
        return InProgressList(
          entitiesFilterData: filter,
          onItemClick: onSwapItemClick,
        );
      case DexListType.history:
        return HistoryList(
          entitiesFilterData: filter,
          onItemClick: onSwapItemClick,
        );
      case DexListType.swap:
        return const TakerForm();
    }
  }
}

class _MobileWidget extends StatelessWidget {
  final DexListType type;
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
    if (type == DexListType.swap) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
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
            listType: type,
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
                    listType: type,
                  )
                : child,
          ),
        ],
      );
    }
  }
}

class _DesktopWidget extends StatelessWidget {
  final DexListType type;
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
    if (type == DexListType.swap) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
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
            listType: type,
          ),
          Flexible(child: child),
        ],
      );
    }
  }
}
