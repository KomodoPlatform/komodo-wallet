import 'dart:async';

import 'package:dragon_logs/dragon_logs.dart';
import 'package:intl/intl.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/services/logger/log_message.dart';
import 'package:web_dex/services/logger/logger.dart';
import 'package:web_dex/services/logger/logger_metadata_mixin.dart';
import 'package:web_dex/services/platform_info/platform_info.dart';
import 'package:web_dex/shared/utils/utils.dart' as initialised_logger show log;

class UniversalLogger with LoggerMetadataMixin implements LoggerInterface {
  UniversalLogger({required this.platformInfo});

  bool _isInitialized = false;
  bool _isBusyInit = false;

  final PlatformInfo platformInfo;

  @override
  Future<void> init() async {
    if (_isInitialized || _isBusyInit) return;

    final timer = Stopwatch()..start();

    try {
      await DragonLogs.init();

      initialised_logger
          .log('Logger initialized in ${timer.elapsedMilliseconds}ms');

      _isInitialized = true;
    } catch (e) {
      // ignore: avoid_print
      print(
        'Failed to initialize app logging. Downloaded logs '
        'may be incomplete.\n${e.toString()}',
      );
    } finally {
      timer.stop();
      _isBusyInit = false;
    }
  }

  @override
  Future<void> write(String message, [String? path]) async {
    // If logger is not initialized, fall back to simple print
    if (!_isInitialized) {
      // ignore: avoid_print
      print('[$path] $message');
      return;
    }

    final date = DateTime.now();

    final LogMessage logMessage = LogMessage(
      path: path,
      appVersion: packageInformation.packageVersion ?? '',
      mm2Version: DragonLogs.sessionMetadata?['mm2Version'],
      appLocale: await localeName(),
      platform: platformInfo.platform,
      osLanguage: platformInfo.osLanguage,
      screenSize: platformInfo.screenSize ?? '',
      timestamp: date.millisecondsSinceEpoch,
      message: message,
      date: date.toString(),
    );

    // Convert to JSON but exclude fields which are already set in the session
    // metadata and non-null.
    final Map<String, dynamic> json = logMessage.toJson()
      ..removeWhere(
        (key, value) =>
            DragonLogs.sessionMetadata!.containsKey(key) || value == null,
      );

    return log(json.toString());
  }

  @override
  Future<void> getLogFile() async {
    if (!_isInitialized) {
      // ignore: avoid_print
      print('Logger not initialized, cannot export log file');
      return;
    }

    final String date =
        DateFormat('dd.MM.yyyy_HH-mm-ss').format(DateTime.now());
    final String filename = 'komodo_wallet_log_$date';

    await FileLoader.fromPlatform().save(
      fileName: filename,
      data: await DragonLogs.exportLogsString(),
      type: LoadFileType.compressed,
    );
  }
}
