import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/market_maker_bot_order_list_repository.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/dex_list_type.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/services/orders_service/my_orders_service.dart';
import 'package:web_dex/shared/ui/clock_warning_banner.dart';
import 'package:web_dex/shared/widgets/hidden_without_wallet.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/dex/dex_tab_bar.dart';
import 'package:web_dex/views/dex/entities_list/dex_list_wrapper.dart';
import 'package:web_dex/views/dex/entity_details/trading_details.dart';

class DexPage extends StatefulWidget {
  const DexPage({super.key});

  @override
  State<DexPage> createState() => _DexPageState();
}

class _DexPageState extends State<DexPage> {
  bool isTradingDetails = false;

  @override
  void initState() {
    routingState.dexState.addListener(_onRouteChange);
    super.initState();
  }

  @override
  void dispose() {
    routingState.dexState.removeListener(_onRouteChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tradingEntitiesBloc =
        RepositoryProvider.of<TradingEntitiesBloc>(context);
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    final myOrdersService = RepositoryProvider.of<MyOrdersService>(context);

    final pageContent = MultiBlocProvider(
      providers: [
        BlocProvider<DexTabBarBloc>(
          key: const Key('dex-page'),
          create: (BuildContext context) => DexTabBarBloc(
            RepositoryProvider.of<KomodoDefiSdk>(context),
            tradingEntitiesBloc,
            MarketMakerBotOrderListRepository(
              myOrdersService,
              SettingsRepository(),
              coinsRepository,
            ),
          )..add(const ListenToOrdersRequested()),
        ),
      ],
      child: isTradingDetails
          ? TradingDetails(uuid: routingState.dexState.uuid)
          : _DexContent(),
    );
    return pageContent;
  }

  void _onRouteChange() {
    setState(
      () => isTradingDetails = routingState.dexState.isTradingDetails,
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
              margin: isMobile ? const EdgeInsets.only(top: 14) : null,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _backgroundColor(context),
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
    return DexListType.values.length > tabIndex;
  }
}
