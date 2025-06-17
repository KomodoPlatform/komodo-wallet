import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/assets_overview/bloc/asset_overview_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/dispatchers/popup_dispatcher.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/kdf_auth_metadata_extension.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/router/state/wallet_state.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/analytics/events.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/portfolio_growth_chart.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/portfolio_profit_loss_chart.dart';
import 'package:web_dex/views/wallet/wallet_page/charts/coin_prices_chart.dart';
import 'package:web_dex/views/wallet/wallet_page/common/assets_list.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/active_coins_list.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/wallet_manage_section.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/wallet_overview.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_wrapper.dart';

class WalletMain extends StatefulWidget {
  const WalletMain({super.key = const Key('wallet-page')});

  @override
  State<WalletMain> createState() => _WalletMainState();
}

class _WalletMainState extends State<WalletMain>
    with SingleTickerProviderStateMixin {
  bool _showCoinWithBalance = false;
  String _searchKey = '';
  PopupDispatcher? _popupDispatcher;
  StreamSubscription<Wallet?>? _walletSubscription;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  late final Stopwatch _walletListStopwatch;
  bool _walletHalfLogged = false;

  @override
  void initState() {
    super.initState();

    _walletListStopwatch = Stopwatch()..start();
    _scrollController.addListener(_onScroll);

    final authBloc = context.read<AuthBloc>();
    if (authBloc.state.currentUser != null) {
      _loadWalletData(authBloc.state.currentUser!.wallet.id).ignore();
    }

    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    _popupDispatcher?.close();
    _popupDispatcher = null;
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthBlocState>(
      // This should only load / refresh wallet data if the user changes
      listenWhen: (previous, current) =>
          previous.currentUser != current.currentUser,
      listener: (context, state) {
        if (state.currentUser?.wallet != null) {
          _loadWalletData(state.currentUser!.wallet.id).ignore();
        } else {
          _clearWalletData();
        }
      },
      builder: (authContext, authState) {
        final authStateMode = authState.currentUser == null
            ? AuthorizeMode.noLogin
            : AuthorizeMode.logIn;
        return BlocBuilder<CoinsBloc, CoinsState>(
          builder: (context, state) {
            final walletCoinsFiltered = state.walletCoins.values.toList();

            return PageLayout(
              noBackground: true,
              header:
                  isMobile ? PageHeader(title: LocaleKeys.wallet.tr()) : null,
              content: Expanded(
                child: Column(
                  children: [
                    if (authStateMode == AuthorizeMode.logIn) ...[
                      WalletOverview(
                        key: const Key('wallet-overview'),
                        onPortfolioGrowthPressed: () =>
                            _tabController.animateTo(1),
                        onPortfolioProfitLossPressed: () =>
                            _tabController.animateTo(2),
                        onAssetsPressed: () => _tabController.animateTo(0),
                      ),
                      const Gap(8),
                      // Tab structure with charts and coins list using NestedScrollView
                      Expanded(
                        child: NestedScrollView(
                          headerSliverBuilder:
                              (BuildContext context, bool innerBoxIsScrolled) {
                            return <Widget>[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TabBar(
                                      controller: _tabController,
                                      tabs: [
                                        Tab(text: LocaleKeys.assets.tr()),
                                        Tab(
                                            text: LocaleKeys.portfolioGrowth
                                                .tr()),
                                        Tab(
                                            text:
                                                LocaleKeys.profitAndLoss.tr()),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ];
                          },
                          body: TabBarView(
                            // // Clamp to horizontal scrolling
                            // physics: const NeverScrollableScrollPhysics(),
                            controller: _tabController,
                            children: [
                              // Coins List Tab
                              CustomScrollView(
                                // physics: const ClampingScrollPhysics(),
                                key: const Key('wallet-page-scroll-view'),
                                controller: _scrollController,
                                slivers: [
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: _SliverSearchBarDelegate(
                                      withBalance: _showCoinWithBalance,
                                      onSearchChange: _onSearchChange,
                                      onWithBalanceChange:
                                          _onShowCoinsWithBalanceClick,
                                      mode: authStateMode,
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(height: 8),
                                  ),
                                  CoinListView(
                                    mode: authStateMode,
                                    searchPhrase: _searchKey,
                                    withBalance: _showCoinWithBalance,
                                    onActiveCoinItemTap: _onActiveCoinItemTap,
                                    onAssetItemTap: _onAssetItemTap,
                                  ),
                                ],
                              ),
                              // Portfolio Growth Chart Tab
                              SingleChildScrollView(
                                child: Container(
                                  width: double.infinity,
                                  height: 340,
                                  child: PortfolioGrowthChart(
                                    initialCoins: walletCoinsFiltered,
                                  ),
                                ),
                              ),
                              // Profit/Loss Chart Tab
                              SingleChildScrollView(
                                child: Container(
                                  width: double.infinity,
                                  height: 340,
                                  child: PortfolioProfitLossChart(
                                    initialCoins: walletCoinsFiltered,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // For non-logged in users, show the price chart and coins list
                      const SizedBox(
                        width: double.infinity,
                        height: 340,
                        child: PriceChartPage(key: Key('price-chart')),
                      ),
                      const Gap(8),
                      Expanded(
                        child: CustomScrollView(
                          key: const Key('wallet-page-scroll-view'),
                          controller: _scrollController,
                          slivers: <Widget>[
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _SliverSearchBarDelegate(
                                withBalance: _showCoinWithBalance,
                                onSearchChange: _onSearchChange,
                                onWithBalanceChange:
                                    _onShowCoinsWithBalanceClick,
                                mode: authStateMode,
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(height: 8),
                            ),
                            CoinListView(
                              mode: authStateMode,
                              searchPhrase: _searchKey,
                              withBalance: _showCoinWithBalance,
                              onActiveCoinItemTap: _onActiveCoinItemTap,
                              onAssetItemTap: _onAssetItemTap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadWalletData(String walletId) async {
    final portfolioGrowthBloc = context.read<PortfolioGrowthBloc>();
    final profitLossBloc = context.read<ProfitLossBloc>();
    final assetOverviewBloc = context.read<AssetOverviewBloc>();
    final sdk = RepositoryProvider.of<KomodoDefiSdk>(context);

    // Use the historical (previously activated) wallet coins here, as the
    // [CoinsBloc] state might not be updated yet if the user signs in on this
    // page. Having this function refresh on [CoinsBloc] state changes is not
    // ideal, as it would spam API requests each time a coin is activated, or
    // balance updated.
    // TODO: update to event-based approach based on soon-to-be-implemented
    // balance events from the SDK
    final walletCoins = await sdk.getWalletCoins();

    portfolioGrowthBloc.add(
      PortfolioGrowthLoadRequested(
        coins: walletCoins,
        fiatCoinId: 'USDT',
        selectedPeriod: portfolioGrowthBloc.state.selectedPeriod,
        walletId: walletId,
      ),
    );

    profitLossBloc.add(
      ProfitLossPortfolioChartLoadRequested(
        coins: walletCoins,
        selectedPeriod: profitLossBloc.state.selectedPeriod,
        fiatCoinId: 'USDT',
        walletId: walletId,
      ),
    );

    assetOverviewBloc
      ..add(
        PortfolioAssetsOverviewLoadRequested(
          coins: walletCoins,
          walletId: walletId,
        ),
      )
      ..add(
        PortfolioAssetsOverviewSubscriptionRequested(
          coins: walletCoins,
          walletId: walletId,
          updateFrequency: const Duration(minutes: 1),
        ),
      );
  }

  void _clearWalletData() {
    final portfolioGrowthBloc = context.read<PortfolioGrowthBloc>();
    final profitLossBloc = context.read<ProfitLossBloc>();
    final assetOverviewBloc = context.read<AssetOverviewBloc>();

    portfolioGrowthBloc.add(const PortfolioGrowthClearRequested());
    profitLossBloc.add(const ProfitLossPortfolioChartClearRequested());
    assetOverviewBloc.add(const AssetOverviewClearRequested());
  }

  void _onShowCoinsWithBalanceClick(bool? value) {
    setState(() {
      _showCoinWithBalance = value ?? false;
    });
  }

  void _onSearchChange(String searchKey) {
    setState(() {
      _searchKey = searchKey.toLowerCase();
    });
  }

  void _onActiveCoinItemTap(Coin coin) {
    routingState.walletState.selectedCoin = coin.abbr;
    routingState.walletState.action = coinsManagerRouteAction.none;
  }

  void _onAssetItemTap(Coin coin) {
    _popupDispatcher = _createPopupDispatcher();
    _popupDispatcher!.show();
  }

  void _onScroll() {
    if (_walletHalfLogged || !_scrollController.hasClients) return;

    final half = MediaQuery.of(context).size.height / 2;
    if (_scrollController.offset >= half) {
      _walletHalfLogged = true;
      final coinsCount = context.read<CoinsBloc>().state.walletCoins.length;
      context.read<AnalyticsBloc>().logEvent(
            WalletListHalfViewportReachedEventData(
              timeToHalfMs: _walletListStopwatch.elapsedMilliseconds,
              walletSize: coinsCount,
            ),
          );
    }
  }

  PopupDispatcher _createPopupDispatcher() {
    final TakerBloc takerBloc = context.read<TakerBloc>();
    final BridgeBloc bridgeBloc = context.read<BridgeBloc>();

    return PopupDispatcher(
      width: 320,
      context: scaffoldKey.currentContext ?? context,
      barrierColor: isMobile ? Theme.of(context).colorScheme.onSurface : null,
      borderColor: theme.custom.specificButtonBorderColor,
      popupContent: WalletsManagerWrapper(
        eventType: WalletsManagerEventType.wallet,
        onSuccess: (_) async {
          takerBloc.add(TakerReInit());
          bridgeBloc.add(const BridgeReInit());
          await reInitTradingForms(context);
          _popupDispatcher?.close();
        },
      ),
    );
  }
}

class CoinListView extends StatelessWidget {
  const CoinListView({
    super.key,
    required this.mode,
    required this.searchPhrase,
    required this.withBalance,
    required this.onActiveCoinItemTap,
    required this.onAssetItemTap,
  });

  final AuthorizeMode mode;
  final String searchPhrase;
  final bool withBalance;
  final Function(Coin) onActiveCoinItemTap;
  final Function(Coin) onAssetItemTap;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case AuthorizeMode.logIn:
        return ActiveCoinsList(
          searchPhrase: searchPhrase,
          withBalance: withBalance,
          onCoinItemTap: onActiveCoinItemTap,
        );
      case AuthorizeMode.hiddenLogin:
      case AuthorizeMode.noLogin:
        return AssetsList(
          useGroupedView: true,
          assets: context
              .read<CoinsBloc>()
              .state
              .coins
              .values
              .map((coin) => coin.assetId)
              .toList(),
          withBalance: false,
          searchPhrase: searchPhrase,
          onAssetItemTap: (assetId) => onAssetItemTap(
            context
                .read<CoinsBloc>()
                .state
                .coins
                .values
                .firstWhere((coin) => coin.assetId == assetId),
          ),
        );
    }
  }
}

class _SliverSearchBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverSearchBarDelegate({
    required this.withBalance,
    required this.onSearchChange,
    required this.onWithBalanceChange,
    required this.mode,
  });
  final bool withBalance;
  final Function(String) onSearchChange;
  final Function(bool) onWithBalanceChange;
  final AuthorizeMode mode;

  @override
  final double minExtent = 132;
  @override
  final double maxExtent = 155;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // return SizedBox.expand();

    return WalletManageSection(
      withBalance: withBalance,
      onSearchChange: onSearchChange,
      onWithBalanceChange: onWithBalanceChange,
      mode: mode,
      pinned: shrinkOffset > 0,
    );
  }

  @override
  bool shouldRebuild(_SliverSearchBarDelegate oldDelegate) {
    return withBalance != oldDelegate.withBalance || mode != oldDelegate.mode;
  }
}
