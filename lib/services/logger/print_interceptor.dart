import 'dart:async';

import 'package:web_dex/services/logger/logger.dart';

/// Intercepts `print` output and persists it via the app logger.
///
/// - Buffers lines printed before the logger is ready
/// - Flushes buffered lines once initialized
/// - Forwards subsequent prints to the logger
class PrintInterceptor {
  PrintInterceptor._();

  static final List<String> _earlyPrintBuffer = <String>[];
  static bool _forwardPrintsToLogger = false;

  /// Create a ZoneSpecification that mirrors prints to the logger.
  static ZoneSpecification createZoneSpec(LoggerInterface logger) {
    return ZoneSpecification(
      print: (self, parent, zone, line) {
        parent.print(zone, line);
        if (_forwardPrintsToLogger) {
          // fire-and-forget to avoid blocking the print
          // coverage:ignore-line - fire-and-forget
          logger.write(line, 'print');
        } else {
          _earlyPrintBuffer.add(line);
        }
      },
    );
  }

  /// Initialize the logger and flush any buffered prints.
  static Future<void> initAndFlush(LoggerInterface logger) async {
    await logger.init();
    for (final line in _earlyPrintBuffer) {
      // coverage:ignore-line - fire-and-forget
      logger.write(line, 'print');
    }
    _earlyPrintBuffer.clear();
    _forwardPrintsToLogger = true;
  }
}

