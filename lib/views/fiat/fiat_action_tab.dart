import 'dart:async';

import 'package:flutter/material.dart';
import 'package:komodo_wallet/shared/ui/ui_tab_bar/ui_tab.dart';
import 'package:komodo_wallet/shared/ui/ui_tab_bar/ui_tab_bar.dart';

class FiatActionTabBar extends StatefulWidget {
  const FiatActionTabBar({
    Key? key,
    required this.currentTabIndex,
    required this.onTabClick,
  }) : super(key: key);
  final int currentTabIndex;
  final Function(int) onTabClick;

  @override
  State<FiatActionTabBar> createState() => _FiatActionTabBarState();
}

class _FiatActionTabBarState extends State<FiatActionTabBar> {
  final List<StreamSubscription> _listeners = [];

  @override
  void initState() {
    _onDataChange(null);

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
          key: const Key('fiat-buy-tab'),
          text: 'Buy crypto',
          isSelected: widget.currentTabIndex == 0,
          onClick: () => widget.onTabClick(0),
        ),
        UiTab(
          key: const Key('fiat-sell-tab'),
          text: 'Sell crypto',
          isSelected: widget.currentTabIndex == 1,
          onClick: () => widget.onTabClick(1),
        ),
      ],
    );
  }

  void _onDataChange(dynamic _) {
    if (!mounted) return;
  }
}
