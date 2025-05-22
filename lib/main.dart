import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_coin_updates/komodo_coin_updates.dart';
import 'package:web/web.dart' as web;
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/bloc/app_bloc_observer.dart';
import 'package:web_dex/bloc/app_bloc_root.dart' deferred as app_bloc_root;
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/bloc/cex_market_data/cex_market_data.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/runtime_coin_updates/runtime_update_config_provider.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/blocs/startup_bloc.dart';
import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/performance_analytics/performance_analytics.dart';
import 'package:web_dex/services/logger/get_logger.dart';
import 'package:web_dex/shared/utils/platform_tuner.dart';
import 'package:web_dex/shared/utils/utils.dart';

part 'services/initializer/app_bootstrapper.dart';

PerformanceMode? _appDemoPerformanceMode;

PerformanceMode? get appDemoPerformanceMode =>
    _appDemoPerformanceMode ?? _getPerformanceModeFromUrl();

Future<void> main() async {
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  await AppBootstrapper.instance.ensureInitialized();

  Bloc.observer = AppBlocObserver();

  PerformanceAnalytics.init();

  runApp(
    EasyLocalization(
      supportedLocales: localeList,
      fallbackLocale: localeList.first,
      useFallbackTranslations: true,
      useOnlyLangCode: true,
      path: '$assetsPath/translations',
      child: MyApp(),
    ),
  );
}

PerformanceMode? _getPerformanceModeFromUrl() {
  String? maybeEnvPerformanceMode;

  maybeEnvPerformanceMode =
      const bool.hasEnvironment('DEMO_MODE_PERFORMANCE')
          ? const String.fromEnvironment('DEMO_MODE_PERFORMANCE')
          : null;

  if (kIsWeb) {
    final url = web.window.location.href;
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
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(authRepo: authRepo)),
      ],
      child: app_bloc_root.AppBlocRoot(
        storedPrefs: _storedSettings!,
        runtimeUpdateConfig: _runtimeUpdateConfig!,
      ),
    );
  }
}
