import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:web_dex/model/dex_list_type.dart';
import 'package:web_dex/shared/ui/ui_tab_bar/ui_tab.dart';
import 'package:web_dex/shared/ui/ui_tab_bar/ui_tab_bar.dart';

class DexTabBar extends StatelessWidget {
  const DexTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    const values = DexListType.values;
    return BlocBuilder<DexTabBarBloc, DexTabBarState>(
      builder: (context, state) {
        final DexTabBarBloc bloc = context.read<DexTabBarBloc>();
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
          child: UiTabBar(
            currentTabIndex: state.tabIndex,
            tabs: List.generate(values.length, (index) {
              final tab = values[index];
              return UiTab(
                key: Key(tab.key),
                text: tab.name(state),
                isSelected: state.tabIndex == index,
                onClick: () => bloc.add(TabChanged(index)),
              );
            }),
          ),
        );
      },
    );
  }
}
