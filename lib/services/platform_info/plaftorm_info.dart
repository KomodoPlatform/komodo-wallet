import 'package:flutter/foundation.dart';
import 'package:komodo_wallet/services/platform_info/native_platform_info.dart';
import 'package:komodo_wallet/services/platform_info/web_platform_info.dart';

abstract class PlatformInfo {
  String get osLanguage;
  String get platform;
  String? get screenSize;

  static PlatformInfo getInstance() {
    if (kIsWeb) {
      return WebPlatformInfo();
    } else {
      return NativePlatformInfo();
    }
  }
}

mixin MemoizedPlatformInfoMixin {
  String? _osLanguage;
  String? _platform;
  String? _screenSize;

  String get osLanguage => _osLanguage ??= computeOsLanguage();
  String get platform => _platform ??= computePlatform();
  String? get screenSize => _screenSize ??= computeScreenSize();

  String computeOsLanguage();
  String computePlatform();
  String? computeScreenSize();
}
