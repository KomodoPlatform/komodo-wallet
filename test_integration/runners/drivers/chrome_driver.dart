// ignore_for_file: avoid_print

import 'chrome_config_manager.dart';
import 'find.dart';
import 'web_browser_driver.dart';
import 'web_driver_process_mixin.dart';

class ChromeDriver extends WebBrowserDriver with WebDriverProcessMixin {
  ChromeDriver({
    this.port = 4444,
    this.silent = true,
    this.enableChromeLogs = true,
    this.logFilePath = 'chromedriver.log',
  }) {
    chromeConfigManager = ChromeConfigManager(findFlutterRoot());
  }

  @override
  final int port;
  final bool silent;
  final bool enableChromeLogs;
  final String logFilePath;
  @override
  String get driverName => 'ChromeDriver';
  late final ChromeConfigManager chromeConfigManager;

  @override
  Future<void> start() async {
    final args = [
      '--port=$port',
      '--log-path=$logFilePath',
      if (silent) '--silent',
      if (enableChromeLogs) '--enable-chrome-logs',
    ];

    await startDriver('chromedriver', args);
  }

  @override
  Future<void> stop() async {
    try {
      chromeConfigManager.restoreChromeConfiguration();
    } catch (e) {
      print('Failed to restore Chrome configuration: $e');
    }
    await stopDriver();
  }

  @override
  Future<void> reset() async {
    chromeConfigManager.restoreChromeConfiguration();
  }

  @override
  Future<void> blockUrl(String url, {String redirectUrl = '127.0.0.1'}) async {
    chromeConfigManager.appendArgsToChromeConfiguration([
      '--host-resolver-rules=MAP $url $redirectUrl',
    ]);
  }
}
