// ignore_for_file: avoid_print

import 'web_browser_driver.dart';
import 'web_driver_process_mixin.dart';

class SafariDriver extends WebBrowserDriver with WebDriverProcessMixin {
  SafariDriver({
    this.port = 4444,
    this.verbose = true,
  });

  @override
  final int port;
  final bool verbose;

  @override
  String get driverName => 'SafariDriver';

  @override
  Future<void> start() async {
    final args = [
      '-p',
      port.toString(),
      if (verbose) '--diagnose',
    ];

    await startDriver('safaridriver', args);
  }

  @override
  Future<void> stop() => stopDriver();
  
  @override
  Future<void> blockUrl(String url) async {
    // not supported
  }
}
