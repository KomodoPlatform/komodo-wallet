part of 'package:web_dex/main.dart';

final class AppBootstrapper {
  AppBootstrapper._();

  static AppBootstrapper get instance => _instance;

  static final _instance = AppBootstrapper._();

  bool _isInitialized = false;

  Future<void> ensureInitialized(KomodoDefiSdk kdfSdk) async {
    if (_isInitialized) return;

    final timer = Stopwatch()..start();
    await logger.init();

    log('AppBootstrapper: Log initialized in ${timer.elapsedMilliseconds}ms');
    timer.reset();

    await _warmUpInitializers().awaitAll();
    log('AppBootstrapper: Warm-up initializers completed in ${timer.elapsedMilliseconds}ms');
    timer.stop();

    _isInitialized = true;
  }

  /// A list of futures that should be completed before the app starts
  /// ([runApp]) which do not depend on each other.
  List<Future<void>> _warmUpInitializers() {
    return [
      app_bloc_root.loadLibrary(),
      packageInformation.init(),
      EasyLocalization.ensureInitialized(),
      CexMarketData.ensureInitialized(),
      PlatformTuner.setWindowTitleAndSize(),
      SettingsRepository.loadStoredSettings()
          .then((stored) => _storedSettings = stored),
      _initHive(isWeb: kIsWeb || kIsWasm, appFolder: appFolder).then(
        (_) => sparklineRepository.init(),
      ),
    ];
  }
}

Future<void> _initHive({required bool isWeb, required String appFolder}) async {
  if (isWeb) {
    return Hive.initFlutter(appFolder);
  }

  final appDirectory = await getApplicationDocumentsDirectory();
  final path = p.join(appDirectory.path, appFolder);
  return Hive.init(path);
}

StoredSettings? _storedSettings;
