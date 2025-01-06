import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_coin_updates/komodo_coin_updates.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';
import 'package:web_dex/bloc/assets_overview/bloc/asset_overview_bloc.dart';
import 'package:web_dex/bloc/assets_overview/investment_repository.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/bloc/bitrefill/bloc/bitrefill_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_repository.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/generator.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/mock_transaction_history_repository.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_repository.dart';
import 'package:web_dex/bloc/cex_market_data/price_chart/price_chart_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/price_chart/price_chart_event.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_repository.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/dex_repository.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_repository.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/market_maker_bot_order_list_repository.dart';
import 'package:web_dex/bloc/nfts/nft_main_bloc.dart';
import 'package:web_dex/bloc/nfts/nft_main_repo.dart';
import 'package:web_dex/bloc/runtime_coin_updates/coin_config_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/bloc/system_health/system_health_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_bloc.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/bloc/trezor_connection_bloc/trezor_connection_bloc.dart';
import 'package:web_dex/blocs/blocs.dart';
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
    Key? key,
    required this.storedPrefs,
    required this.runtimeUpdateConfig,
  });

  final StoredSettings storedPrefs;
  final RuntimeUpdateConfig runtimeUpdateConfig;

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

    final transactionsRepo = performanceMode != null
        ? MockTransactionHistoryRepo(
            api: mm2Api,
            client: Client(),
            performanceMode: performanceMode,
            demoDataGenerator: DemoDataCache.withDefaults(),
          )
        : TransactionHistoryRepo(api: mm2Api, client: Client());

    final profitLossRepo = ProfitLossRepository.withDefaults(
      transactionHistoryRepo: transactionsRepo,
      cexRepository: binanceRepository,
      // Returns real data if performanceMode is null. Consider changing the
      // other repositories to use this pattern.
      demoMode: performanceMode,
    );

    final portfolioGrowthRepo = PortfolioGrowthRepository.withDefaults(
      transactionHistoryRepo: transactionsRepo,
      cexRepository: binanceRepository,
      demoMode: performanceMode,
    );

    _clearCachesIfPerformanceModeChanged(
      performanceMode,
      profitLossRepo,
      portfolioGrowthRepo,
    );

    return MultiRepositoryProvider(
      providers: [RepositoryProvider(create: (_) => NftsRepo(api: mm2Api.nft))],
      child: MultiBlocProvider(
        providers: [
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
            ),
          ),
          BlocProvider<TransactionHistoryBloc>(
            create: (BuildContext ctx) => TransactionHistoryBloc(
              repo: transactionsRepo,
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
              authRepo: authRepo,
              dexRepository: dexRepository,
              coinsRepository: coinsBloc,
            ),
          ),
          BlocProvider<BridgeBloc>(
            create: (context) => BridgeBloc(
              authRepository: authRepo,
              dexRepository: dexRepository,
              bridgeRepository: BridgeRepository.instance,
              coinsRepository: coinsBloc,
            ),
          ),
          BlocProvider(
            create: (_) => TrezorConnectionBloc(
              trezorRepo: trezorRepo,
              authRepo: authRepo,
              walletRepo: currentWalletBloc,
            ),
            lazy: false,
          ),
          BlocProvider(
            lazy: false,
            create: (context) => NftMainBloc(
              repo: context.read<NftsRepo>(),
              authRepo: authRepo,
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
              ),
            ),
          ),
          BlocProvider<SystemHealthBloc>(
            create: (_) => SystemHealthBloc(),
          ),
          BlocProvider<CoinConfigBloc>(
            lazy: false,
            create: (_) => CoinConfigBloc(
              coinsConfigRepo: CoinConfigRepository.withDefaults(
                runtimeUpdateConfig,
              ),
            )
              ..add(CoinConfigLoadRequested())
              ..add(CoinConfigUpdateSubscribeRequested()),
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
  final RootRouteInformationParser _routeInformationParser =
      RootRouteInformationParser();
  late final AirDexBackButtonDispatcher _airDexBackButtonDispatcher;

  @override
  void initState() {
    _airDexBackButtonDispatcher = AirDexBackButtonDispatcher(_routerDelegate);
    routingState.selectedMenu = MainMenuValue.defaultMenu();

    if (kDebugMode) initDebugData(context.read<AuthBloc>());

    unawaited(_hideAppLoader());

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

    _precacheCoinIcons().ignore();
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

  Future<void> _precacheCoinIcons() async {
    if (_currentPrecacheOperation != null &&
        !_currentPrecacheOperation!.isCompleted) {
      _currentPrecacheOperation!
          .completeError('New request to precache icons started.');
    }

    _currentPrecacheOperation = Completer<void>();

    try {
      final coins = (await coinsRepo.getKnownCoins()).map((coin) => coin.abbr);

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
