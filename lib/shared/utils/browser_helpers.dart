import 'package:web/web.dart';
import 'dart:ui_web' as ui_web;

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
      final String ua = window.navigator.userAgent.toLowerCase();
      final info = BrowserInfo(
        browserName: _getBrowserName(ua),
        browserVersion: _getBrowserVersion(ua),
        os: _getOs(ua),
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

  static String _getOs(ua) {
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
    final HTMLBodyElement? body = document.body as HTMLBodyElement?;
    final width = document.documentElement?.clientWidth ?? body?.clientWidth;
    final height = document.documentElement?.clientHeight ?? body?.clientHeight;

    return '${width ?? ''}:${height ?? ''}';
  }
}

bool isChromeBrowser() {
  final vendor = window.navigator.vendor;
  final userAgent = window.navigator.userAgent.toLowerCase();
  final engine =
      ui_web.browser.detectBrowserEngineByVendorAgent(vendor, userAgent);
  final bool isBlink = engine == ui_web.BrowserEngine.blink;
  final bool isEdge = userAgent.contains('edg/');
  return isBlink &&
      !isEdge &&
      vendor == 'Google Inc.' &&
      userAgent.contains('chrome');
}
