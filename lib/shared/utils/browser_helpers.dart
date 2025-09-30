import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart';

class BrowserInfo {
  final String browserName;
  final String browserVersion;
  final String os;
  final String screenSize;

  BrowserInfo({
    required this.browserName,
    required this.browserVersion,
    required this.os,
    required this.screenSize,
  });
}

class BrowserInfoParser {
  static BrowserInfo? _cached;

  static BrowserInfo get() {
    final cached = _cached;
    if (cached == null) {
      final userAgent = window.navigator.userAgent.toLowerCase();
      final info = BrowserInfo(
        browserName: _getBrowserName(userAgent),
        browserVersion: _getBrowserVersion(userAgent),
        os: _getOs(userAgent),
        screenSize: _getScreenSize(),
      );
      _cached = info;

      return info;
    } else {
      return BrowserInfo(
        browserName: cached.browserName,
        browserVersion: cached.browserVersion,
        os: cached.os,
        screenSize: _getScreenSize(),
      );
    }
  }

  static bool get isChrome => get().browserName == 'chrome';

  static String _getOs(String ua) {
    if (ua.contains('windows')) {
      return 'windows';
    } else if (ua.contains('android')) {
      return 'android';
    } else if (ua.contains('macintosh')) {
      return 'mac';
    } else if (ua.contains('iphone') || ua.contains('ipad')) {
      return 'ios';
    } else if (ua.contains('linux')) {
      return 'linux';
    }
    return 'unknown';
  }

  static String _getBrowserName(String ua) {
    if (ua.contains('edg/')) {
      return 'edge';
    } else if (ua.contains('opr/')) {
      return 'opera';
    } else if (ua.contains('chrome')) {
      return 'chrome';
    } else if (ua.contains('safari')) {
      return 'safari';
    } else if (ua.contains('firefox')) {
      return 'firefox';
    } else if (ua.contains('brave')) {
      return 'brave';
    }
    return 'unknown';
  }

  static String _getBrowserVersion(String ua) {
    String? browserVersion;
    if (ua.contains('edg/')) {
      browserVersion = RegExp('edg/([^s|;]*)').firstMatch(ua)?.group(1);
    } else if (ua.contains('opr/')) {
      browserVersion = RegExp('opr/([^s|;]*)').firstMatch(ua)?.group(1);
    } else if (ua.contains('chrome')) {
      browserVersion = RegExp('chrome/([^s|;]*)').firstMatch(ua)?.group(1);
    } else if (ua.contains('safari')) {
      browserVersion = RegExp('version/([^s|;]*)').firstMatch(ua)?.group(1);
    } else if (ua.contains('firefox')) {
      browserVersion = RegExp('firefox/([^s|;]*)').firstMatch(ua)?.group(1);
    } else if (ua.contains('brave')) {
      browserVersion = RegExp('brave/([^s|;]*)').firstMatch(ua)?.group(1);
    }
    return browserVersion ?? 'unknown';
  }

  static String _getScreenSize() {
    final HTMLElement? body = document.body;
    final width = document.documentElement?.clientWidth ?? body?.clientWidth;
    final height = document.documentElement?.clientHeight ?? body?.clientHeight;

    return '${width ?? ''}:${height ?? ''}';
  }
}

@JS('navigator.brave.isBrave')
external JSPromise<JSBoolean>? _jsIsBrave();

Future<bool> isBraveApiAvailable() async {
  try {
    final jsPromise = _jsIsBrave();
    if (jsPromise == null) return false;
    final jsBool = await jsPromise.toDart;
    return jsBool.toDart;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error checking if Brave API is available: $e');
    }
    // Catch all exceptions, including JavaScript errors that might not
    // be properly wrapped as Dart exceptions
    return false;
  }
}
