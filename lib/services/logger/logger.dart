import 'dart:typed_data';

abstract class LoggerInterface {
  Future<void> init();
  Future<void> write(String logMessage, [String? path]);
  Future<void> getLogFile();
  Future<Uint8List> exportRecentLogsBytes({int maxBytes});
}
