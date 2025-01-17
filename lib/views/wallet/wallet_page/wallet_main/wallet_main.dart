import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/assets_overview/bloc/asset_overview_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc_event.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc_state.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/dispatchers/popup_dispatcher.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/mm2_sw.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/router/state/wallet_state.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/portfolio_growth_chart.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/portfolio_profit_loss_chart.dart';
import 'package:web_dex/views/wallet/wallet_page/charts/coin_prices_chart.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/active_coins_list.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/all_coins_list.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/wallet_manage_section.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/wallet_overview.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_wrapper.dart';

class WalletMain extends StatefulWidget {
  const WalletMain({Key? key = const Key('wallet-page')}) : super(key: key);

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

  @override
  void initState() {
    super.initState();

    if (isRunningAsChromeExtension()) handleExtensionLogin();

    if (currentWalletBloc.wallet != null) {
      _loadWalletData(currentWalletBloc.wallet!.id);
    }

    _walletSubscription = currentWalletBloc.outWallet.listen((wallet) {
      if (wallet != null) {
        _loadWalletData(wallet.id);
      } else {
        _clearWalletData();
      }
    });

    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> handleExtensionLogin() async {
    final authBloc = BlocProvider.of<AuthBloc>(context);

    // Logged in
    if (authBloc.state.mode != AuthorizeMode.noLogin) {
      return;
    }

    // Not logged in, show wallet selection
    if (await mm2.status() != MM2Status.rpcIsUp) {
      _showWalletSelectionPopup();
      return;
    }

    // RPC is logged in, try auto-login the UI
    await walletsBloc.fetchSavedWallets();
    final wallets = walletsBloc.wallets;

    if (wallets.isEmpty) {
      _showWalletSelectionPopup();
    } else {
      final lastLoginWalletId = await getStorage().read('lastLoginWalletId');
      final Wallet? lastLoginWallet =
          wallets.firstWhereOrNull((wallet) => wallet.id == lastLoginWalletId);

      if (lastLoginWallet == null) {
        _showWalletSelectionPopup();
      } else {
        authBloc.add(AuthReLogInEvent(seed: '', wallet: lastLoginWallet));
      }
    }
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    _popupDispatcher?.close();
    _popupDispatcher = null;
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletCoinsFiltered = coinsBloc.walletCoinsMap.values;

    final authState = context.select((AuthBloc bloc) => bloc.state.mode);

    if (isRunningAsChromeExtension()) {
      return PageLayout(
        header: isMobile && !isRunningAsChromeExtension()
            ? PageHeader(title: LocaleKeys.wallet.tr())
            : null,
        content: Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: BlocBuilder<AuthBloc, AuthBlocState>(
                  builder: (context, state) {
                    final AuthorizeMode mode = state.mode;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const WalletOverview(),
                        WalletManageSection(
                          withBalance: _showCoinWithBalance,
                          onSearchChange: _onSearchChange,
                          onWithBalanceChange: _onShowCoinsWithBalanceClick,
                          mode: mode,
                          pinned: true,
                        ),
                        SizedBox(
                            height: isRunningAsChromeExtension() ? 0 : 18.0),
                        Flexible(
                          child: _buildCoinList(mode),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PageLayout(
        noBackground: true,
        header: isMobile ? PageHeader(title: LocaleKeys.wallet.tr()) : null,
        content: Expanded(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (authState == AuthorizeMode.logIn) ...[
                      WalletOverview(
                        onPortfolioGrowthPressed: () =>
                            _tabController.animateTo(0),
                        onPortfolioProfitLossPressed: () =>
                            _tabController.animateTo(1),
                      ),
                      const Gap(8),
                    ],
                    if (authState != AuthorizeMode.logIn)
                      const SizedBox(
                        width: double.infinity,
                        height: 340,
                        child: PriceChartPage(key: Key('price-chart')),
                      )
                    else ...[
                      Card(
                        child: TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: LocaleKeys.portfolioGrowth.tr()),
                            Tab(text: LocaleKeys.profitAndLoss.tr()),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 340,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 340,
                              child: PortfolioGrowthChart(
                                initialCoins: walletCoinsFiltered.toList(),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 340,
                              child: PortfolioProfitLossChart(
                                initialCoins: walletCoinsFiltered.toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Gap(8),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverSearchBarDelegate(
                  withBalance: _showCoinWithBalance,
                  onSearchChange: _onSearchChange,
                  onWithBalanceChange: _onShowCoinsWithBalanceClick,
                  mode: authState,
                ),
              ),
              _buildCoinList(authState),
            ],
          ),
        ));
  }

  void _loadWalletData(String walletId) {
    final portfolioGrowthBloc = context.read<PortfolioGrowthBloc>();
    final profitLossBloc = context.read<ProfitLossBloc>();
    final assetOverviewBloc = context.read<AssetOverviewBloc>();

    portfolioGrowthBloc.add(
      PortfolioGrowthLoadRequested(
        coins: coinsBloc.walletCoins,
        fiatCoinId: 'USDT',
        updateFrequency: const Duration(minutes: 1),
        selectedPeriod: portfolioGrowthBloc.state.selectedPeriod,
        walletId: walletId,
      ),
    );

    profitLossBloc.add(
      ProfitLossPortfolioChartLoadRequested(
        coins: coinsBloc.walletCoins,
        selectedPeriod: profitLossBloc.state.selectedPeriod,
        fiatCoinId: 'USDT',
        walletId: walletId,
      ),
    );

    assetOverviewBloc
      ..add(
        PortfolioAssetsOverviewLoadRequested(
          coins: coinsBloc.walletCoins,
          walletId: walletId,
        ),
      )
      ..add(
        PortfolioAssetsOverviewSubscriptionRequested(
          coins: coinsBloc.walletCoins,
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

  Widget _buildCoinList(AuthorizeMode mode) {
    switch (mode) {
      case AuthorizeMode.logIn:
        return ActiveCoinsList(
          searchPhrase: _searchKey,
          withBalance: _showCoinWithBalance,
          onCoinItemTap: _onActiveCoinItemTap,
        );
      case AuthorizeMode.hiddenLogin:
      case AuthorizeMode.noLogin:
        return AllCoinsList(
          searchPhrase: _searchKey,
          withBalance: _showCoinWithBalance,
          onCoinItemTap: _onCoinItemTap,
        );
    }
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

  void _onCoinItemTap(Coin coin) {
    _popupDispatcher = _createPopupDispatcher();
    _popupDispatcher!.show();
  }

  PopupDispatcher _createPopupDispatcher(
      {bool expanded = false, bool barrierDismissable = true}) {
    final ctx = scaffoldKey.currentContext ?? context;
    final TakerBloc takerBloc = ctx.read<TakerBloc>();
    final BridgeBloc bridgeBloc = ctx.read<BridgeBloc>();

    return PopupDispatcher(
      width: 320,
      expanded: expanded,
      context: ctx,
      barrierColor: isMobile ? Theme.of(ctx).colorScheme.surface : null,
      borderColor: theme.custom.specificButtonBorderColor,
      barrierDismissible: barrierDismissable,
      popupContent: WalletsManagerWrapper(
        eventType: WalletsManagerEventType.wallet,
        onSuccess: (_) async {
          takerBloc.add(TakerReInit());
          bridgeBloc.add(const BridgeReInit());
          await reInitTradingForms();
          _popupDispatcher?.close();
        },
      ),
    );
  }

  Future<void> _showWalletSelectionPopup() async {
    _popupDispatcher =
        _createPopupDispatcher(expanded: true, barrierDismissable: false);
    _popupDispatcher!.show();
  }
}

class _SliverSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final bool withBalance;
  final Function(String) onSearchChange;
  final Function(bool) onWithBalanceChange;
  final AuthorizeMode mode;

  _SliverSearchBarDelegate({
    required this.withBalance,
    required this.onSearchChange,
    required this.onWithBalanceChange,
    required this.mode,
  });

  @override
  double get minExtent => 120;
  @override
  double get maxExtent => 120;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
