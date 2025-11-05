import 'dart:async';

import 'package:komodo_defi_framework/komodo_defi_framework.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/services/devtools/devtools_integration_service.dart';

/// Interceptor that listens to KDF framework logs and forwards RPC calls to DevTools
class KdfLogInterceptor {
  KdfLogInterceptor._();

  static final KdfLogInterceptor _instance = KdfLogInterceptor._();
  static KdfLogInterceptor get instance => _instance;

  StreamSubscription<LogRecord>? _subscription;

  /// Initialize the interceptor to capture RPC logs
  void initialize() {
    // Enable KDF debug logging to capture RPC calls
    KomodoDefiFramework.enableDebugLogging = true;

    // Ensure the KDF loggers are set to INFO level or lower
    Logger('KomodoDefiFramework').level = Level.ALL;
    Logger('KdfApiClient').level = Level.ALL;

    // Listen to logger records
    _subscription?.cancel();
    _subscription = Logger.root.onRecord
        .where(
          (record) =>
              record.loggerName == 'KomodoDefiFramework' ||
              record.loggerName == 'KdfApiClient' ||
              record.loggerName.startsWith('KomodoDefi'),
        )
        .listen(_handleLogRecord);
  }

  void _handleLogRecord(LogRecord record) {
    final message = record.message;

    // Debug: Log all messages from KDF framework loggers
    print(
      '[KdfLogInterceptor] Received log from ${record.loggerName}: $message',
    );

    // Parse RPC log messages
    // Format: "[RPC] method_name completed in XXXms"
    // or: "[RPC] method_name failed after XXXms: error"
    if (message.startsWith('[RPC]')) {
      print('[KdfLogInterceptor] Parsing RPC log: $message');
      _parseRpcLog(message, record);
    } else if (message.contains('completed in') && message.contains('ms')) {
      // Some logs might not have [RPC] prefix
      print(
        '[KdfLogInterceptor] Found potential RPC log without prefix: $message',
      );
      _parseAlternativeRpcLog(message, record);
    }
  }

  void _parseRpcLog(String message, LogRecord record) {
    // Extract method name and duration
    final rpcMatch = RegExp(
      r'\[RPC\] (\S+) (completed|failed) (?:in|after) (\d+)ms',
    ).firstMatch(message);
    if (rpcMatch != null) {
      final method = rpcMatch.group(1) ?? 'unknown';
      final status = rpcMatch.group(2) == 'completed' ? 'success' : 'error';
      final durationMs = int.tryParse(rpcMatch.group(3) ?? '0') ?? 0;

      // Extract error message if failed
      String? errorMessage;
      if (status == 'error') {
        final errorIndex = message.indexOf(': ', rpcMatch.end);
        if (errorIndex != -1) {
          errorMessage = message.substring(errorIndex + 2);
        }
      }

      print(
        '[KdfLogInterceptor] Posting RPC call from _parseRpcLog: $method ($status) - ${durationMs}ms',
      );

      // Post to DevTools
      DevToolsIntegrationService.instance.postRpcCall(
        id: '${record.time.millisecondsSinceEpoch}_${method.hashCode}',
        method: method,
        status: status,
        startTimestamp: record.time.subtract(
          Duration(milliseconds: durationMs),
        ),
        endTimestamp: record.time,
        durationMs: durationMs,
        metadata: {
          if (errorMessage != null) 'errorMessage': errorMessage,
          'logLevel': record.level.name,
        },
      );
    }
  }

  void _parseAlternativeRpcLog(String message, LogRecord record) {
    // Try to extract method name and duration from logs without [RPC] prefix
    // Example: "method_name completed in 123ms"
    final match = RegExp(
      r'(\S+)\s+(completed|failed)\s+(?:in|after)\s+(\d+)ms',
    ).firstMatch(message);
    if (match != null) {
      final method = match.group(1) ?? 'unknown';
      final status = match.group(2) == 'completed' ? 'success' : 'error';
      final durationMs = int.tryParse(match.group(3) ?? '0') ?? 0;

      print(
        '[KdfLogInterceptor] Posting RPC call: $method ($status) - ${durationMs}ms',
      );

      // Post to DevTools
      DevToolsIntegrationService.instance.postRpcCall(
        id: '${record.time.millisecondsSinceEpoch}_${method.hashCode}',
        method: method,
        status: status,
        startTimestamp: record.time.subtract(
          Duration(milliseconds: durationMs),
        ),
        endTimestamp: record.time,
        durationMs: durationMs,
        metadata: {
          'logLevel': record.level.name,
          'source': 'alternative_parse',
        },
      );
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Check if a log message is RPC-related (to avoid double logging)
  static bool isRpcLogMessage(String message) {
    // Check if it's an RPC log pattern
    return message.startsWith('[RPC]') ||
        message.startsWith('[ELECTRUM]') ||
        // Also check for RPC method names in SDK logs
        (message.contains('completed in') && message.contains('ms')) ||
        (message.contains('failed after') && message.contains('ms')) ||
        // Some SDK logs mention specific RPC methods
        (message.contains('RPC response:')) ||
        (message.contains('mm2Rpc request'));
  }
}
