import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:komodo_wallet/shared/ui/ui_tab_bar/ui_tab.dart';
import 'package:komodo_wallet/shared/ui/ui_tab_bar/ui_tab_bar.dart';
import 'package:komodo_wallet/views/market_maker_bot/market_maker_bot_tab_type.dart';

class MarketMakerBotTabBar extends StatelessWidget {
  const MarketMakerBotTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    const tabBarEntries = MarketMakerBotTabType.values;

    return BlocBuilder<DexTabBarBloc, DexTabBarState>(
      builder: (context, state) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
          child: UiTabBar(
            currentTabIndex: state.tabIndex,
            tabs: List.generate(
              tabBarEntries.length,
              (index) {
                final tab = tabBarEntries[index];
                return UiTab(
                  key: Key(tab.key),
                  text: tab.name(state),
                  isSelected: state.tabIndex == index,
                  onClick: () =>
                      context.read<DexTabBarBloc>().add(TabChanged(index)),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
