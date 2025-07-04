import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:komodo_wallet/services/logger/log_message.dart';

String formatLogs(Iterable<LogMessage> logs) {
  final logIterable = logs.map((e) => jsonEncode(e));

  final buffer = StringBuffer('[\n');

  buffer.writeAll(logIterable, ',\n');

  buffer.write('\n]');

  return buffer.toString();
}

Future<String> formatLogsExport(Iterable<LogMessage> logs) async {
  final result = await compute<Iterable<LogMessage>, String>(formatLogs, logs);

  return result;
}
