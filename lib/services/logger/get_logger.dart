import 'dart:developer' as developer show log;
import 'dart:io';

import 'package:dragon_logs/dragon_logs.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/performance_analytics/performance_analytics.dart';
import 'package:web_dex/services/logger/logger.dart';
import 'package:web_dex/services/logger/mock_logger.dart';
import 'package:web_dex/services/logger/universal_logger.dart';
import 'package:web_dex/services/platform_info/platform_info.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/constants.dart' show isTestMode;

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

  Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.onRecord.listen(_logToUniversalLogger);
}

/// Copied over existing code from utils.dart log function to avoid breaking
/// changes.
/// TODO: update to do othe outstanding stacktrace parsing etc.
/// (presumably for security reasons)
Future<void> _logToUniversalLogger(LogRecord record) async {
  final timer = Stopwatch()..start();
  // todo(yurii & ivan): to finish stacktrace parsing
  // if (trace != null) {
  //   final String errorTrace = getInfoFromStackTrace(trace);
  //   logger.write('$errorTrace: $errorOrUsefulData');
  // }
  const isTestEnv = isTestMode || kDebugMode;
  if (isTestEnv && record.error != null) {
    _logDeveloperLog(record);
  }

  try {
    // Temporarily add log level to the message, seeing as the universal logger
    // does not support log levels yet.
    final message = '${record.level.name}: ${record.message} - ${record.error}';
    await logger.write(message, record.loggerName);

    // Web previews are built in profile mode, so print the stack trace for
    // debugging purposes in case errors are found in PR testing.
    if (kProfileMode && record.stackTrace != null) {
      await logger.write('\nStacktrace: ${record.stackTrace}\n');
    }

    performance.logTimeWritingLogs(timer.elapsedMilliseconds);
  } catch (e) {
    // TODO: replace below with crashlytics reporting or show UI the printed
    // message in a snackbar/banner.
    // ignore: avoid_print
    print(
      'ERROR: Writing logs failed. Exported log files may be incomplete.'
      '\nError message: $e',
    );
  } finally {
    timer.stop();
  }
}

void _logDeveloperLog(LogRecord record) {
  final message =
      '${record.level.name} [${record.loggerName}]: ${record.time}: '
      '${record.message}';

  switch (record.level) {
    case Level.SEVERE:
    case Level.SHOUT:
      developer.log(
        message,
        name: record.loggerName,
        level: 1200, // Error level
        error: record.error,
        stackTrace: record.stackTrace,
      );
    case Level.WARNING:
      developer.log(
        message,
        name: record.loggerName,
        level: 900, // Warning level
      );
    default:
      developer.log(
        message,
        name: record.loggerName,
        level: 500, // Info level
      );
  }
}
