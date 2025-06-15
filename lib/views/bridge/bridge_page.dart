import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/router/state/bridge_section_state.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/shared/ui/clock_warning_banner.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/hidden_without_wallet.dart';
import 'package:web_dex/views/bridge/bridge_form.dart';
import 'package:web_dex/views/bridge/bridge_tab_bar.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/dex/entities_list/history/history_list.dart';
import 'package:web_dex/views/dex/entities_list/in_progress/in_progress_list.dart';
import 'package:web_dex/views/dex/entity_details/trading_details.dart';

class BridgePage extends StatefulWidget {
  const BridgePage() : super(key: const Key('bridge-page'));

  @override
  State<StatefulWidget> createState() => _BridgePageState();
}

class _BridgePageState extends State<BridgePage> with TickerProviderStateMixin {
  int _activeTabIndex = 0;
  bool _showSwap = false;

  @override
  void initState() {
    routingState.bridgeState.addListener(_onRouteChange);
    super.initState();
  }

  @override
  void dispose() {
    routingState.bridgeState.removeListener(_onRouteChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state.mode == AuthorizeMode.noLogin) {
          setState(() {
            _activeTabIndex = 0;
          });
        }
      },
      child: Builder(builder: (context) {
        final page = _showSwap ? _buildTradingDetails() : _buildBridgePage();
        return page;
      }),
    );
  }

  Widget _buildTradingDetails() {
    return TradingDetails(
      uuid: routingState.bridgeState.uuid,
    );
  }

  Widget _buildBridgePage() {
    return PageLayout(
      content: Expanded(
        child: Container(
          margin: isMobile ? const EdgeInsets.only(top: 14) : null,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
          decoration: BoxDecoration(
            color: _backgroundColor(context),
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: theme.custom.dexFormWidth),
                child: HiddenWithoutWallet(
                  child: BridgeTabBar(
                    currentTabIndex: _activeTabIndex,
                    onTabClick: _setActiveTab,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: ClockWarningBanner(),
              ),
              Flexible(
                child: _TabContent(
                  activeTabIndex: _activeTabIndex,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setActiveTab(int i) {
    setState(() {
      _activeTabIndex = i;
    });
  }

  Color? _backgroundColor(BuildContext context) {
    if (isMobile) {
      final ThemeMode mode = theme.mode;
      return mode == ThemeMode.dark ? null : Theme.of(context).cardColor;
    }
    return null;
  }

  void _onRouteChange() {
    setState(() {
      _showSwap =
          routingState.bridgeState.action == BridgeAction.tradingDetails;
    });
  }
}

class _TabContent extends StatelessWidget {
  final int _activeTabIndex;
  const _TabContent({required int activeTabIndex})
      : _activeTabIndex = activeTabIndex;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabContents = [
      const BridgeForm(),
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: InProgressList(
            filter: _bridgeSwapsFilter, onItemClick: _onSwapItemClick),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: HistoryList(
          filter: _bridgeSwapsFilter,
          onItemClick: _onSwapItemClick,
        ),
      ),
    ];

    return tabContents[_activeTabIndex];
  }

  void _onSwapItemClick(Swap swap) {
    routingState.bridgeState.setDetailsAction(swap.uuid);
  }

  bool _bridgeSwapsFilter(Swap swap) {
    return abbr2Ticker(swap.sellCoin) == abbr2Ticker(swap.buyCoin);
  }
}
