import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';
import 'package:web_dex/bloc/assets_overview/bloc/asset_overview_bloc.dart';
import 'package:web_dex/bloc/assets_overview/investment_repository.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/bitrefill/bloc/bitrefill_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_repository.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_repository.dart';
import 'package:web_dex/bloc/cex_market_data/price_chart/price_chart_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/price_chart/price_chart_event.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_repository.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/dex_repository.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_repository.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/market_maker_bot_order_list_repository.dart';
import 'package:web_dex/bloc/nfts/nft_main_bloc.dart';
import 'package:web_dex/bloc/nfts/nft_main_repo.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/bloc/system_health/system_clock_repository.dart';
import 'package:web_dex/bloc/system_health/system_health_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_bloc.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/bloc/trezor_connection_bloc/trezor_connection_bloc.dart';
import 'package:web_dex/bloc/trezor_init_bloc/trezor_init_bloc.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/blocs/kmd_rewards_bloc.dart';
import 'package:web_dex/blocs/maker_form_bloc.dart';
import 'package:web_dex/blocs/orderbook_bloc.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/blocs/trezor_coins_bloc.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/main.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/main_menu_value.dart';
import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/router/navigators/app_router_delegate.dart';
import 'package:web_dex/router/navigators/back_dispatcher.dart';
import 'package:web_dex/router/parsers/root_route_parser.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/services/orders_service/my_orders_service.dart';
import 'package:web_dex/shared/utils/debug_utils.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/coin_icon.dart';

class AppBlocRoot extends StatelessWidget {
  const AppBlocRoot({
    required this.storedPrefs,
    required this.komodoDefiSdk,
    super.key,
  });

  final StoredSettings storedPrefs;
  final KomodoDefiSdk komodoDefiSdk;

  // TODO: Refactor to clean up the bloat in this main file
  void _clearCachesIfPerformanceModeChanged(
    PerformanceMode? performanceMode,
    ProfitLossRepository profitLossRepo,
    PortfolioGrowthRepository portfolioGrowthRepo,
  ) async {
    final sharedPrefs = await SharedPreferences.getInstance();

    final storedLastPerformanceMode =
        sharedPrefs.getString('last_performance_mode');

    if (storedLastPerformanceMode != performanceMode?.name) {
      profitLossRepo.clearCache().ignore();
      portfolioGrowthRepo.clearCache().ignore();
    }
    if (performanceMode == null) {
      sharedPrefs.remove('last_performance_mode').ignore();
    } else {
      sharedPrefs
          .setString('last_performance_mode', performanceMode.name)
          .ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final performanceMode = appDemoPerformanceMode;

    final mm2Api = RepositoryProvider.of<Mm2Api>(context);
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    final myOrdersService = MyOrdersService(mm2Api);
    final tradingEntitiesBloc = TradingEntitiesBloc(
      komodoDefiSdk,
      mm2Api,
      myOrdersService,
    );
    final currentWalletBloc = RepositoryProvider.of<CurrentWalletBloc>(context);
    final dexRepository = DexRepository(mm2Api);
    final trezorRepo = RepositoryProvider.of<TrezorRepo>(context);
    final trezorBloc = RepositoryProvider.of<TrezorCoinsBloc>(context);

    // TODO: SDK Port needed, not sure about this part
    final transactionsRepo = /*performanceMode != null
        ? MockTransactionHistoryRepo(
            api: mm2Api,
            client: Client(),
            performanceMode: performanceMode,
            demoDataGenerator: DemoDataCache.withDefaults(),
          )
        : */
        TransactionHistoryRepo(sdk: komodoDefiSdk);

    final profitLossRepo = ProfitLossRepository.withDefaults(
      transactionHistoryRepo: transactionsRepo,
      cexRepository: binanceRepository,
      // Returns real data if performanceMode is null. Consider changing the
      // other repositories to use this pattern.
      demoMode: performanceMode,
      coinsRepository: coinsRepository,
      mm2Api: mm2Api,
      sdk: komodoDefiSdk,
    );

    final portfolioGrowthRepo = PortfolioGrowthRepository.withDefaults(
      transactionHistoryRepo: transactionsRepo,
      cexRepository: binanceRepository,
      demoMode: performanceMode,
      coinsRepository: coinsRepository,
      mm2Api: mm2Api,
      sdk: komodoDefiSdk,
    );

    _clearCachesIfPerformanceModeChanged(
      performanceMode,
      profitLossRepo,
      portfolioGrowthRepo,
    );

    // startup bloc run steps
    tradingEntitiesBloc.runUpdate();
    routingState.selectedMenu = MainMenuValue.dex;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => NftsRepo(
            api: mm2Api.nft,
            coinsRepo: coinsRepository,
          ),
        ),
        RepositoryProvider(create: (_) => tradingEntitiesBloc),
        RepositoryProvider(create: (_) => dexRepository),
        RepositoryProvider(
          create: (_) => MakerFormBloc(
            api: mm2Api,
            kdfSdk: komodoDefiSdk,
            coinsRepository: coinsRepository,
            dexRepository: dexRepository,
          ),
        ),
        RepositoryProvider(create: (_) => OrderbookBloc(api: mm2Api)),
        RepositoryProvider(create: (_) => myOrdersService),
        RepositoryProvider(
          create: (_) => KmdRewardsBloc(coinsRepository, mm2Api),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => CoinsBloc(
              komodoDefiSdk,
              currentWalletBloc,
              coinsRepository,
              trezorBloc,
              mm2Api,
            )..add(CoinsStarted()),
          ),
          BlocProvider<PriceChartBloc>(
            create: (context) => PriceChartBloc(binanceRepository)
              ..add(
                const PriceChartStarted(
                  symbols: ['KMD'],
                  period: Duration(days: 30),
                ),
              ),
          ),
          BlocProvider<AssetOverviewBloc>(
            create: (context) => AssetOverviewBloc(
              investmentRepository: InvestmentRepository(
                profitLossRepository: profitLossRepo,
              ),
              profitLossRepository: profitLossRepo,
            ),
          ),
          BlocProvider<ProfitLossBloc>(
            create: (context) => ProfitLossBloc(
              profitLossRepository: profitLossRepo,
            ),
          ),
          BlocProvider<PortfolioGrowthBloc>(
            create: (BuildContext ctx) => PortfolioGrowthBloc(
              portfolioGrowthRepository: portfolioGrowthRepo,
              coinsRepository: coinsRepository,
            ),
          ),
          BlocProvider<TransactionHistoryBloc>(
            create: (BuildContext ctx) => TransactionHistoryBloc(
              sdk: komodoDefiSdk,
            ),
          ),
          BlocProvider<SettingsBloc>(
            create: (context) =>
                SettingsBloc(storedPrefs, SettingsRepository()),
          ),
          BlocProvider<AnalyticsBloc>(
            // lazy: false,
            create: (context) => AnalyticsBloc(
              analytics: FirebaseAnalyticsRepo(storedPrefs.analytics),
              storedData: storedPrefs,
              repository: SettingsRepository(),
            ),
          ),
          BlocProvider<TakerBloc>(
            create: (context) => TakerBloc(
              kdfSdk: komodoDefiSdk,
              dexRepository: dexRepository,
              coinsRepository: coinsRepository,
            ),
          ),
          BlocProvider<BridgeBloc>(
            create: (context) => BridgeBloc(
              kdfSdk: komodoDefiSdk,
              dexRepository: dexRepository,
              bridgeRepository: BridgeRepository(
                mm2Api,
                komodoDefiSdk,
                coinsRepository,
              ),
              coinsRepository: coinsRepository,
            ),
          ),
          BlocProvider(
            create: (_) => TrezorConnectionBloc(
              trezorRepo: trezorRepo,
              kdfSdk: komodoDefiSdk,
              walletRepo: RepositoryProvider.of<CurrentWalletBloc>(context),
            ),
            lazy: false,
          ),
          BlocProvider(
            lazy: false,
            create: (context) => NftMainBloc(
              repo: context.read<NftsRepo>(),
              kdfSdk: komodoDefiSdk,
              isLoggedIn:
                  context.read<AuthBloc>().state.mode == AuthorizeMode.logIn,
            ),
          ),
          if (isBitrefillIntegrationEnabled)
            BlocProvider(
              create: (context) =>
                  BitrefillBloc()..add(const BitrefillLoadRequested()),
            ),
          BlocProvider<MarketMakerBotBloc>(
            create: (context) => MarketMakerBotBloc(
              MarketMakerBotRepository(
                mm2Api,
                SettingsRepository(),
              ),
              MarketMakerBotOrderListRepository(
                myOrdersService,
                SettingsRepository(),
                coinsRepository,
              ),
            ),
          ),
          BlocProvider<SystemHealthBloc>(
            create: (_) => SystemHealthBloc(SystemClockRepository(), mm2Api),
          ),
          BlocProvider<TrezorInitBloc>(
            create: (context) => TrezorInitBloc(
              kdfSdk: komodoDefiSdk,
              trezorRepo: trezorRepo,
              coinsRepository: coinsRepository,
            ),
          ),
        ],
        child: _MyAppView(),
      ),
    );
  }
}

class _MyAppView extends StatefulWidget {
  @override
  State<_MyAppView> createState() => _MyAppViewState();
}

class _MyAppViewState extends State<_MyAppView> {
  final AppRouterDelegate _routerDelegate = AppRouterDelegate();
  late final RootRouteInformationParser _routeInformationParser;
  late final AirDexBackButtonDispatcher _airDexBackButtonDispatcher;

  @override
  void initState() {
    final coinsBloc = context.read<CoinsBloc>();
    _routeInformationParser = RootRouteInformationParser(coinsBloc);
    _airDexBackButtonDispatcher = AirDexBackButtonDispatcher(_routerDelegate);
    routingState.selectedMenu = MainMenuValue.defaultMenu();

    unawaited(_hideAppLoader());

    if (kDebugMode) {
      final walletsRepo = RepositoryProvider.of<WalletsRepository>(context);
      final authBloc = context.read<AuthBloc>();
      initDebugData(authBloc, walletsRepo).ignore();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (_) => appTitle,
      themeMode: context
          .select((SettingsBloc settingsBloc) => settingsBloc.state.themeMode),
      darkTheme: theme.global.dark,
      theme: theme.global.light,
      routerDelegate: _routerDelegate,
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      routeInformationParser: _routeInformationParser,
      backButtonDispatcher: _airDexBackButtonDispatcher,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    _precacheCoinIcons(coinsRepository).ignore();
  }

  /// Hides the native app launch loader. Currently only implemented for web.
  // TODO: Consider using ab abstract class with separate implementations for
  // web and native to avoid web-code in code concerning all platforms.
  Future<void> _hideAppLoader() async {
    if (kIsWeb) {
      html.document.getElementById('main-content')?.style.display = 'block';

      final loadingElement = html.document.getElementById('loading');

      if (loadingElement == null) return;

      // Trigger the zoom out animation.
      loadingElement.classes.add('init_done');

      // Await 200ms so the user can see the animation.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Remove the loading indicator.
      loadingElement.remove();
    }
  }

  Completer<void>? _currentPrecacheOperation;

  Future<void> _precacheCoinIcons(CoinsRepo coinsRepo) async {
    if (_currentPrecacheOperation != null &&
        !_currentPrecacheOperation!.isCompleted) {
      // completeError throws an uncaught exception, which causes the UI
      // tests to fail when switching between light and dark theme
      log('New request to precache icons started.');
      _currentPrecacheOperation!.complete();
    }

    _currentPrecacheOperation = Completer<void>();

    try {
      final coins = coinsRepo.getKnownCoinsMap().keys;

      await for (final abbr in Stream.fromIterable(coins)) {
        // TODO: Test if necessary to complete prematurely with error if build
        // context is stale. Alternatively, we can check if the context is
        // not mounted and return early with error.
        // ignore: use_build_context_synchronously
        // if (context.findRenderObject() == null) {
        //   _currentPrecacheOperation!.completeError('Build context is stale.');
        //   return;
        // }

        // ignore: use_build_context_synchronously
        await CoinIcon.precacheCoinIcon(context, abbr)
            .onError((_, __) => debugPrint('Error precaching coin icon $abbr'));
      }

      _currentPrecacheOperation!.complete();
    } catch (e) {
      log('Error precaching coin icons: $e');
      _currentPrecacheOperation!.completeError(e);
    }
  }
}
