import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/mm2/mm2_sw.dart';
import 'package:web_dex/model/dex_list_type.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/shared/ui/clock_warning_banner.dart';
import 'package:web_dex/shared/widgets/hidden_without_wallet.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/dex/dex_tab_bar.dart';
import 'package:web_dex/views/dex/entities_list/dex_list_wrapper.dart';
import 'package:web_dex/views/dex/entity_details/trading_details.dart';

class DexPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (kIsWalletOnly) {
      return const Placeholder(child: Text('You should not see this page'));
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider<DexTabBarBloc>(
          key: const Key('dex-page'),
          create: (BuildContext context) => DexTabBarBloc(
            DexTabBarState.initial(),
            authRepo,
          ),
        ),
      ],
      child: routingState.dexState.isTradingDetails
          ? TradingDetails(uuid: routingState.dexState.uuid)
          : _DexContent(),
    );
  }
}

class _DexContent extends StatefulWidget {
  @override
  State<_DexContent> createState() => _DexContentState();
}

class _DexContentState extends State<_DexContent> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DexTabBarBloc, DexTabBarState>(
      builder: (BuildContext context, DexTabBarState state) {
        return PageLayout(
          content: Flexible(
            child: Container(
              margin: isMobile && !isRunningAsChromeExtension()
                  ? const EdgeInsets.only(top: 14)
                  : null,
              padding: isRunningAsChromeExtension()
                  ? const EdgeInsets.fromLTRB(0, 12, 0, 0)
                  : const EdgeInsets.fromLTRB(16, 22, 16, 0),
              decoration: BoxDecoration(
                color: _backgroundColor(context),
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const HiddenWithoutWallet(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: DexTabBar(),
                    ),
                  ),
                  const ClockWarningBanner(),
                  Flexible(
                    child: shouldShowTabContent(state.tabIndex)
                        ? DexListWrapper(
                            key: Key('dex-list-wrapper-${state.tabIndex}'),
                            DexListType.values[state.tabIndex],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color? _backgroundColor(BuildContext context) {
    if (isMobile) {
      final ThemeMode mode = theme.mode;
      return mode == ThemeMode.dark ? null : Theme.of(context).cardColor;
    }
    return null;
  }

  bool shouldShowTabContent(int tabIndex) {
    return (DexListType.values.length > tabIndex);
  }
}
