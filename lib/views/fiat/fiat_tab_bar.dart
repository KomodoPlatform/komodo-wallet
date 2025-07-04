import 'dart:async';

import 'package:flutter/material.dart';
import 'package:komodo_wallet/shared/ui/ui_tab_bar/ui_tab.dart';
import 'package:komodo_wallet/shared/ui/ui_tab_bar/ui_tab_bar.dart';

class FiatTabBar extends StatefulWidget {
  const FiatTabBar({
    Key? key,
    required this.currentTabIndex,
    required this.onTabClick,
  }) : super(key: key);
  final int currentTabIndex;
  final Function(int) onTabClick;

  @override
  State<FiatTabBar> createState() => _FiatTabBarState();
}

class _FiatTabBarState extends State<FiatTabBar> {
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
          key: const Key('fiat-form-tab'),
          text: 'Form',
          isSelected: widget.currentTabIndex == 0,
          onClick: () => widget.onTabClick(0),
        ),
        UiTab(
          key: const Key('fiat-second-tab'),
          text: 'In Progress',
          isSelected: widget.currentTabIndex == 1,
          onClick: () => widget.onTabClick(1),
        ),
        UiTab(
          key: const Key('fiat-third-tab'),
          text: 'History',
          isSelected: widget.currentTabIndex == 2,
          onClick: () => widget.onTabClick(2),
        ),
      ],
    );
  }

  void _onDataChange(dynamic _) {
    if (!mounted) return;
  }
}
