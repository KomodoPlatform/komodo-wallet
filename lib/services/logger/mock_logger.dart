// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:web_dex/services/logger/logger.dart';

class MockLogger implements LoggerInterface {
  const MockLogger();

  @override
  Future<void> write(String logMessage, [String? path]) async {
    print('path: $path, $logMessage');
  }

  @override
  Future<void> getLogFile() async {
    print('downloaded');
  }

  @override
  Future<void> init() async {
    print('initialized');
  }

  @override
  Future<Uint8List> exportRecentLogsBytes({
    int maxBytes = 9 * 1024 * 1024,
  }) async {
    final String mock = 'Mock logs: logger not available in this environment.';
    return Uint8List.fromList(mock.codeUnits);
  }
}
