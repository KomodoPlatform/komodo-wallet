import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Service that integrates with Flutter DevTools extensions by posting events
/// and registering service extensions.
class DevToolsIntegrationService {
  DevToolsIntegrationService._();
  
  static final DevToolsIntegrationService _instance = DevToolsIntegrationService._();
  static DevToolsIntegrationService get instance => _instance;
  
  // Log storage for snapshot requests
  final _logBuffer = ListQueue<Map<String, dynamic>>();
  final _rpcBuffer = ListQueue<Map<String, dynamic>>();
  
  // Settings
  static const maxLogBufferSize = 2500;
  static const maxRpcBufferSize = 1500;
  static const logBatchSize = 50;
  static const rpcBatchSize = 50;
  
  bool _isInitialized = false;
  bool _rpcTracingEnabled = true;
  
  Timer? _logBatchTimer;
  Timer? _rpcBatchTimer;
  final _logBatch = <Map<String, dynamic>>[];
  final _rpcBatch = <Map<String, dynamic>>[];
  
  // Event kinds matching the DevTools extension constants
  static const _logBatchEvent = 'ext.komodo.log.batch';
  static const _rpcBatchEvent = 'ext.komodo.rpc.batch';
  
  // Service extension names
  static const _fetchLogSnapshotExt = 'ext.komodo.logs.snapshot';
  static const _fetchRpcSnapshotExt = 'ext.komodo.rpc.snapshot';
  static const _toggleRpcTracingExt = 'ext.komodo.rpc.toggleTracing';
  static const _refreshInsightsExt = 'ext.komodo.rpc.refreshInsights';
  
  /// Initialize the DevTools integration service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Register service extensions
    developer.registerExtension(_fetchLogSnapshotExt, _handleFetchLogSnapshot);
    developer.registerExtension(_fetchRpcSnapshotExt, _handleFetchRpcSnapshot);
    developer.registerExtension(_toggleRpcTracingExt, _handleToggleRpcTracing);
    developer.registerExtension(_refreshInsightsExt, _handleRefreshInsights);
    
    _isInitialized = true;
  }
  
  /// Post a log entry to DevTools extension
  void postLogEntry({
    required String id,
    required DateTime timestamp,
    required Level level,
    required String category,
    required String message,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    if (!_isInitialized || !kDebugMode) return;
    
    final entry = {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': _levelToString(level),
      'category': category,
      'message': message,
      if (metadata != null) 'metadata': metadata,
      if (tags != null) 'tags': tags,
    };
    
    // Add to buffer for snapshot requests
    _addToLogBuffer(entry);
    
    // Batch entries for performance
    _logBatch.add(entry);
    if (_logBatch.length >= logBatchSize) {
      _flushLogBatch();
    } else {
      _logBatchTimer?.cancel();
      _logBatchTimer = Timer(const Duration(milliseconds: 100), _flushLogBatch);
    }
  }
  
  /// Post an RPC call trace to DevTools extension
  void postRpcCall({
    required String id,
    required String method,
    required String status,
    required DateTime startTimestamp,
    DateTime? endTimestamp,
    int? durationMs,
    int? requestBytes,
    int? responseBytes,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isInitialized || !kDebugMode || !_rpcTracingEnabled) return;
    
    final call = {
      'id': id,
      'method': method,
      'status': status,
      'startTimestamp': startTimestamp.toIso8601String(),
      if (endTimestamp != null) 'endTimestamp': endTimestamp.toIso8601String(),
      if (durationMs != null) 'durationMs': durationMs,
      if (requestBytes != null) 'requestBytes': requestBytes,
      if (responseBytes != null) 'responseBytes': responseBytes,
      if (metadata != null) 'metadata': metadata,
    };
    
    // Add to buffer for snapshot requests
    _addToRpcBuffer(call);
    
    // Batch calls for performance
    _rpcBatch.add(call);
    if (_rpcBatch.length >= rpcBatchSize) {
      _flushRpcBatch();
    } else {
      _rpcBatchTimer?.cancel();
      _rpcBatchTimer = Timer(const Duration(milliseconds: 100), _flushRpcBatch);
    }
  }
  
  void _flushLogBatch() {
    if (_logBatch.isEmpty) return;
    
    developer.postEvent(
      _logBatchEvent,
      <String, dynamic>{
        'entries': List<Map<String, dynamic>>.from(_logBatch),
      },
    );
    _logBatch.clear();
    _logBatchTimer?.cancel();
  }
  
  void _flushRpcBatch() {
    if (_rpcBatch.isEmpty) return;
    
    developer.postEvent(
      _rpcBatchEvent,
      <String, dynamic>{
        'calls': List<Map<String, dynamic>>.from(_rpcBatch),
      },
    );
    _rpcBatch.clear();
    _rpcBatchTimer?.cancel();
  }
  
  void _addToLogBuffer(Map<String, dynamic> entry) {
    _logBuffer.addLast(entry);
    while (_logBuffer.length > maxLogBufferSize) {
      _logBuffer.removeFirst();
    }
  }
  
  void _addToRpcBuffer(Map<String, dynamic> call) {
    _rpcBuffer.addLast(call);
    while (_rpcBuffer.length > maxRpcBufferSize) {
      _rpcBuffer.removeFirst();
    }
  }
  
  Future<developer.ServiceExtensionResponse> _handleFetchLogSnapshot(
    String method,
    Map<String, String> parameters,
  ) async {
    // Flush any pending batches first
    _flushLogBatch();
    
    final snapshot = {
      'entries': _logBuffer.toList(),
    };
    
    return developer.ServiceExtensionResponse.result(json.encode(snapshot));
  }
  
  Future<developer.ServiceExtensionResponse> _handleFetchRpcSnapshot(
    String method,
    Map<String, String> parameters,
  ) async {
    // Flush any pending batches first
    _flushRpcBatch();
    
    final snapshot = {
      'calls': _rpcBuffer.toList(),
    };
    
    return developer.ServiceExtensionResponse.result(json.encode(snapshot));
  }
  
  Future<developer.ServiceExtensionResponse> _handleToggleRpcTracing(
    String method,
    Map<String, String> parameters,
  ) async {
    final enabled = parameters['enabled'] == 'true';
    _rpcTracingEnabled = enabled;
    
    return developer.ServiceExtensionResponse.result(
      json.encode({'enabled': _rpcTracingEnabled}),
    );
  }
  
  Future<developer.ServiceExtensionResponse> _handleRefreshInsights(
    String method,
    Map<String, String> parameters,
  ) async {
    // This would trigger server-side insights refresh
    // For now, just return success
    return developer.ServiceExtensionResponse.result(json.encode({}));
  }
  
  String _levelToString(Level level) {
    if (level == Level.SHOUT || level == Level.SEVERE) return 'error';
    if (level == Level.WARNING) return 'warning';
    if (level == Level.INFO) return 'info';
    return 'debug';
  }
  
  /// Dispose of resources
  void dispose() {
    _logBatchTimer?.cancel();
    _rpcBatchTimer?.cancel();
    _flushLogBatch();
    _flushRpcBatch();
  }
}
