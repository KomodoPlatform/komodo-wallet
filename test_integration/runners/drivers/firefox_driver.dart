import 'web_browser_driver.dart';
import 'web_driver_process_mixin.dart';

class FirefoxDriver extends WebBrowserDriver with WebDriverProcessMixin {
  FirefoxDriver({
    this.port = 4444,
    this.verbose = true,
  });

  @override
  final int port;
  final bool verbose;
  @override
  String get driverName => 'GeckoDriver';

  @override
  Future<void> start() async {
    final args = [
      '-p',
      port.toString(),
      if (verbose) '--quiet',
    ];

    await startDriver('geckodriver', args);
  }

  @override
  Future<void> stop() => stopDriver();
  
  @override
  Future<void> blockUrl(String url) async {
    // not supported
  }
}
