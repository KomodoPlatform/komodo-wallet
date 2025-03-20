import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/bloc/app_bloc_observer.dart';
import 'package:web_dex/bloc/app_bloc_root.dart' deferred as app_bloc_root;
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/cex_market_data.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/blocs/trezor_coins_bloc.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api_trezor.dart';
import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/performance_analytics/performance_analytics.dart';
import 'package:web_dex/services/logger/get_logger.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/platform_tuner.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:feedback/feedback.dart';

part 'services/initializer/app_bootstrapper.dart';

PerformanceMode? _appDemoPerformanceMode;

PerformanceMode? get appDemoPerformanceMode =>
    _appDemoPerformanceMode ?? _getPerformanceModeFromUrl();

Future<void> main() async {
  await runZonedGuarded(
    () async {
      usePathUrlStrategy();
      WidgetsFlutterBinding.ensureInitialized();
      Bloc.observer = AppBlocObserver();
      PerformanceAnalytics.init();

      FlutterError.onError = (FlutterErrorDetails details) {
        catchUnhandledExceptions(details.exception, details.stack);
      };

      final KomodoDefiSdk komodoDefiSdk = await mm2.initialize();

      final trezorRepo = TrezorRepo(
        api: Mm2ApiTrezor(mm2.call),
        kdfSdk: komodoDefiSdk,
      );
      final trezor = TrezorCoinsBloc(trezorRepo: trezorRepo);
      final coinsRepo = CoinsRepo(
        kdfSdk: komodoDefiSdk,
        mm2: mm2,
        trezorBloc: trezor,
      );
      final mm2Api = Mm2Api(mm2: mm2, coinsRepo: coinsRepo, sdk: komodoDefiSdk);
      final walletsRepository = WalletsRepository(
        komodoDefiSdk,
        mm2Api,
        getStorage(),
      );

      await AppBootstrapper.instance.ensureInitialized(komodoDefiSdk);
      await initializeLogger(mm2Api);

      runApp(
        EasyLocalization(
          supportedLocales: localeList,
          fallbackLocale: localeList.first,
          useFallbackTranslations: true,
          useOnlyLangCode: true,
          path: '$assetsPath/translations',
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider(create: (_) => komodoDefiSdk),
              RepositoryProvider(create: (_) => mm2Api),
              RepositoryProvider(create: (_) => coinsRepo),
              RepositoryProvider(create: (_) => trezorRepo),
              RepositoryProvider(create: (_) => trezor),
              RepositoryProvider(create: (_) => walletsRepository),
            ],
            child: const MyApp(),
          ),
        ),
      );
    },
    catchUnhandledExceptions,
  );
}

void catchUnhandledExceptions(Object error, StackTrace? stack) {
  log('Uncaught exception: $error.\n$stack');
  debugPrintStack(stackTrace: stack, label: error.toString(), maxFrames: 50);

  // Rethrow the error if it has a stacktrace (valid, traceable error)
  // async errors from the sdk are not traceable so do not rethrow them.
  if (!isTestMode && stack != null && stack.toString().isNotEmpty) {
    Error.throwWithStackTrace(error, stack);
  }
}

PerformanceMode? _getPerformanceModeFromUrl() {
  String? maybeEnvPerformanceMode;

  maybeEnvPerformanceMode = const bool.hasEnvironment('DEMO_MODE_PERFORMANCE')
      ? const String.fromEnvironment('DEMO_MODE_PERFORMANCE')
      : null;

  if (kIsWeb) {
    final url = html.window.location.href;
    final uri = Uri.parse(url);
    maybeEnvPerformanceMode =
        uri.queryParameters['demo_mode_performance'] ?? maybeEnvPerformanceMode;
  }

  switch (maybeEnvPerformanceMode) {
    case 'good':
      return PerformanceMode.good;
    case 'mediocre':
      return PerformanceMode.mediocre;
    case 'very_bad':
      return PerformanceMode.veryBad;
    default:
      return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final komodoDefiSdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    final walletsRepository = RepositoryProvider.of<WalletsRepository>(context);

    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(komodoDefiSdk, walletsRepository),
        ),
      ],
      child: BetterFeedback(
        themeMode: ThemeMode.light,
        darkTheme: _feedbackThemeData(theme),
        theme: _feedbackThemeData(theme),
        child: app_bloc_root.AppBlocRoot(
          storedPrefs: _storedSettings!,
          komodoDefiSdk: komodoDefiSdk,
        ),
      ),
    );
  }
}

FeedbackThemeData _feedbackThemeData(ThemeData appTheme) {
  return FeedbackThemeData(
    bottomSheetTextInputStyle: appTheme.textTheme.bodyMedium!,
    bottomSheetDescriptionStyle: appTheme.textTheme.bodyMedium!,
    dragHandleColor: appTheme.colorScheme.primary,
    colorScheme: appTheme.colorScheme,
    sheetIsDraggable: true,
    drawColors: [
      Colors.red,
      Colors.white,
      Colors.green,
    ],
  );
}
