import 'dart:async';

import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/services/devtools/devtools_integration_service.dart';

/// A wrapper for ApiClient that adds RPC tracking for DevTools
class RpcTrackingClient implements ApiClient {
  RpcTrackingClient(this._innerClient);

  final ApiClient _innerClient;

  @override
  Future<JsonMap> executeRpc(JsonMap request) async {
    final method = request['method'] as String? ?? 'unknown';
    final rpcId = '${DateTime.now().millisecondsSinceEpoch}_${request.hashCode}';
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    // Calculate request size
    final requestBytes = request.toString().length;

    try {
      // Execute the actual RPC call
      final response = await _innerClient.executeRpc(request);
      stopwatch.stop();

      // Calculate response size
      final responseBytes = response.toString().length;

      // Post successful RPC call to DevTools
      DevToolsIntegrationService.instance.postRpcCall(
        id: rpcId,
        method: method,
        status: 'success',
        startTimestamp: startTime,
        endTimestamp: DateTime.now(),
        durationMs: stopwatch.elapsedMilliseconds,
        requestBytes: requestBytes,
        responseBytes: responseBytes,
        metadata: {
          'hasError': response.containsKey('error'),
          if (response.containsKey('error'))
            'errorMessage': response['error'].toString(),
        },
      );

      return response;
    } catch (e) {
      stopwatch.stop();

      // Post failed RPC call to DevTools
      DevToolsIntegrationService.instance.postRpcCall(
        id: rpcId,
        method: method,
        status: 'error',
        startTimestamp: startTime,
        endTimestamp: DateTime.now(),
        durationMs: stopwatch.elapsedMilliseconds,
        requestBytes: requestBytes,
        metadata: {
          'errorType': e.runtimeType.toString(),
          'errorMessage': e.toString(),
        },
      );

      rethrow;
    }
  }

}
