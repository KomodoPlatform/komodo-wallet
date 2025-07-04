import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/shared/ui/clock_warning_banner.dart';
import 'package:komodo_wallet/shared/widgets/hidden_without_wallet.dart';
import 'package:komodo_wallet/views/common/pages/page_layout.dart';
import 'package:komodo_wallet/views/market_maker_bot/market_maker_bot_tab_bar.dart';
import 'package:komodo_wallet/views/market_maker_bot/market_maker_bot_tab_content_wrapper.dart';
import 'package:komodo_wallet/views/market_maker_bot/market_maker_bot_tab_type.dart';

class MarketMakerBotView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DexTabBarBloc, DexTabBarState>(
      builder: (BuildContext context, DexTabBarState state) {
        final listType = MarketMakerBotTabType.values[state.tabIndex];

        return PageLayout(
          content: Flexible(
            child: Container(
              margin: isMobile ? const EdgeInsets.only(top: 14) : null,
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
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
                      child: MarketMakerBotTabBar(),
                    ),
                  ),
                  const ClockWarningBanner(),
                  Flexible(
                    child: MarketMakerBotTabContentWrapper(
                      key: Key('dex-list-wrapper-${state.tabIndex}'),
                      listType,
                      filter: state.filters[listType],
                    ),
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
}
