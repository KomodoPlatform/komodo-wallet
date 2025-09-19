import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/services/platform_info/platform_info.dart';

PlatformInfo createPlatformInfo() => NativePlatformInfo();

class NativePlatformInfo extends PlatformInfo with MemoizedPlatformInfoMixin {
  @override
  String computeOsLanguage() =>
      ui.PlatformDispatcher.instance.locale.toLanguageTag();

  @override
  String computePlatform() =>
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

  @override
  String? computeScreenSize() {
    final currentContext = scaffoldKey.currentContext;
    final size =
        currentContext == null ? null : MediaQuery.of(currentContext).size;
    return size == null ? '' : '${size.width}:${size.height}';
  }

  @override
  Future<PlatformType> computePlatformType() async {
    final os = Platform.operatingSystem.toLowerCase();
    switch (os) {
      case 'android':
        return PlatformType.android;
      case 'ios':
        return PlatformType.ios;
      case 'windows':
        return PlatformType.windows;
      case 'macos':
        return PlatformType.mac;
      case 'linux':
        return PlatformType.linux;
      default:
        return PlatformType.unknown;
    }
  }
}
