import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:komodo_wallet/app_config/app_config.dart';
import 'package:komodo_wallet/services/platform_info/plaftorm_info.dart';

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
}
