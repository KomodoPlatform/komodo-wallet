import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/ui/ui_tab_bar/ui_tab.dart';
import 'package:web_dex/shared/ui/ui_tab_bar/ui_tab_bar.dart';

class BridgeTabBar extends StatefulWidget {
  const BridgeTabBar({
    Key? key,
    required this.currentTabIndex,
    required this.onTabClick,
  }) : super(key: key);
  final int currentTabIndex;
  final Function(int) onTabClick;

  @override
  State<BridgeTabBar> createState() => _BridgeTabBarState();
}

class _BridgeTabBarState extends State<BridgeTabBar> {
  int? _inProgressCount;
  int? _completedCount;
  final List<StreamSubscription> _listeners = [];

  @override
  void initState() {
    _onDataChange(null);

    final tradingEntitiesBloc = RepositoryProvider.of<TradingEntitiesBloc>(
      context,
    );
    _listeners.add(tradingEntitiesBloc.outMyOrders.listen(_onDataChange));
    _listeners.add(tradingEntitiesBloc.outSwaps.listen(_onDataChange));

    super.initState();
  }

  @override
  void dispose() {
    _listeners.map((listener) => listener.cancel());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UiTabBar(
      currentTabIndex: widget.currentTabIndex,
      tabs: [
        UiTab(
          key: const Key('bridge-exchange-tab'),
          text: LocaleKeys.bridgeExchange.tr(),
          isSelected: widget.currentTabIndex == 0,
          onClick: () => widget.onTabClick(0),
        ),
        UiTab(
          key: const Key('bridge-in-progress-tab'),
          text: '${LocaleKeys.inProgress.tr()} ($_inProgressCount)',
          isSelected: widget.currentTabIndex == 1,
          onClick: () => widget.onTabClick(1),
        ),
        UiTab(
          key: const Key('bridge-history-tab'),
          text: '${LocaleKeys.history.tr()} ($_completedCount)',
          isSelected: widget.currentTabIndex == 2,
          onClick: () => widget.onTabClick(2),
        ),
      ],
    );
  }

  void _onDataChange(dynamic _) {
    if (!mounted) return;

    final tradingEntitiesBloc = RepositoryProvider.of<TradingEntitiesBloc>(
      context,
    );
    setState(() {
      _inProgressCount = tradingEntitiesBloc.swaps
          .where((swap) => !swap.isCompleted && swap.isTheSameTicker)
          .length;
      _completedCount = tradingEntitiesBloc.swaps
          .where((swap) => swap.isCompleted && swap.isTheSameTicker)
          .length;
    });
  }
}
