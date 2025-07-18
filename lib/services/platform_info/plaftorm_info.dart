import 'package:flutter/foundation.dart';
import 'package:web_dex/services/platform_info/native_platform_info.dart';
import 'package:web_dex/services/platform_info/web_platform_info.dart';

enum PlatformType {
  chrome,
  firefox,
  safari,
  edge,
  opera,
  brave,
  android,
  ios,
  windows,
  mac,
  linux,
  unknown,
}

abstract class PlatformInfo {
  String get osLanguage;
  String get platform;
  String? get screenSize;
  Future<PlatformType> get platformType;

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
  PlatformType? _platformType;

  String get osLanguage => _osLanguage ??= computeOsLanguage();
  String get platform => _platform ??= computePlatform();
  String? get screenSize => _screenSize ??= computeScreenSize();
  Future<PlatformType> get platformType async =>
      _platformType ??= await computePlatformType();

  String computeOsLanguage();
  String computePlatform();
  String? computeScreenSize();
  Future<PlatformType> computePlatformType();
}
