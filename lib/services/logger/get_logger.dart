import 'dart:io';

import 'package:dragon_logs/dragon_logs.dart';
import 'package:flutter/foundation.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/services/logger/logger.dart';
import 'package:web_dex/services/logger/mock_logger.dart';
import 'package:web_dex/services/logger/universal_logger.dart';
import 'package:web_dex/services/platform_info/plaftorm_info.dart';
import 'package:web_dex/services/storage/get_storage.dart';

final LoggerInterface logger = _getLogger();
LoggerInterface _getLogger() {
  final platformInfo = PlatformInfo.getInstance();

  if (kIsWeb ||
      Platform.isWindows ||
      Platform.isMacOS ||
      Platform.isLinux ||
      Platform.isAndroid ||
      Platform.isIOS) {
    return UniversalLogger(platformInfo: platformInfo);
  }

  return const MockLogger();
}

Future<void> initializeLogger(Mm2Api mm2Api) async {
  final platformInfo = PlatformInfo.getInstance();
  final localeName =
      await getStorage().read('locale').catchError((_) => null) as String? ??
          '';
  DragonLogs.setSessionMetadata({
    'appVersion': packageInformation.packageVersion,
    'mm2Version': await mm2Api.version(),
    'appLanguage': localeName,
    'platform': platformInfo.platform,
    'osLanguage': platformInfo.osLanguage,
    'screenSize': platformInfo.screenSize,
  });
}
