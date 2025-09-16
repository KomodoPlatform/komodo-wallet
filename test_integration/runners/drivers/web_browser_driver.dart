// ignore_for_file: avoid_print

import 'dart:io';

import 'chrome_driver.dart';
import 'firefox_driver.dart';
import 'safari_driver.dart';

abstract class WebBrowserDriver {
  Future<void> start();
  Future<void> stop();
  Future<void> blockUrl(String url);
  Future<void> reset() async {}

  static String findDriverExecutable(String driverName) {
    if (File(driverName).existsSync()) {
      return './$driverName';
    }

    if (Platform.environment['PATH'] != null) {
      for (final path in Platform.environment['PATH']!.split(
        Platform.pathSeparator,
      )) {
        if (File('$path/$driverName').existsSync()) {
          return '$path/$driverName';
        }
      }
    }

    final whichResult = Process.runSync('which', [driverName]);
    if (whichResult.exitCode == 0) {
      return whichResult.stdout.toString().trim();
    }

    final whereResult = Process.runSync('where', [driverName]);
    if (whereResult.exitCode == 0) {
      return whereResult.stdout.toString().trim();
    }

    throw Exception(
      '$driverName not found. Please install it and add it to '
      'PATH or the current directory.',
    );
  }
}

WebBrowserDriver? createWebBrowserDriver({
  required WebBrowser browser,
  int port = 4444,
  bool silent = true,
  bool enableChromeLogs = true,
  String logFilePath = '',
}) {
  if (logFilePath.isEmpty) {
    // ignore: parameter_assignments
    logFilePath = '${browser.driverName}.log';
  }

  switch (browser) {
    case WebBrowser.chrome:
      return ChromeDriver(
        port: port,
        silent: silent,
        enableChromeLogs: enableChromeLogs,
        logFilePath: logFilePath,
      );
    case WebBrowser.safari:
      return SafariDriver(port: port, verbose: true);
    case WebBrowser.firefox:
      return FirefoxDriver(port: port, verbose: !silent);
    // ignore: no_default_cases
    default:
      return null;
  }
}

enum WebBrowser {
  chrome,
  firefox,
  edge,
  safari;

  factory WebBrowser.fromName(String browserName) {
    switch (browserName.toLowerCase()) {
      case 'chrome':
        return WebBrowser.chrome;
      case 'firefox':
        return WebBrowser.firefox;
      case 'edge':
        return WebBrowser.edge;
      case 'safari':
        return WebBrowser.safari;
      default:
        throw ArgumentError('Invalid browser name: $browserName');
    }
  }

  String get driverName {
    switch (this) {
      case WebBrowser.chrome:
        return 'chromedriver';
      case WebBrowser.firefox:
        return 'geckodriver';
      case WebBrowser.edge:
        return 'msedgedriver';
      case WebBrowser.safari:
        return 'safaridriver';
    }
  }
}
