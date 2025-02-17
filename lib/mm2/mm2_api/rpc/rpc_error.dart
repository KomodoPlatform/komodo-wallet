import 'package:equatable/equatable.dart';
import 'package:web_dex/mm2/mm2_api/rpc/rpc_error_type.dart';

class RpcException implements Exception {
  const RpcException(this.error);

  final RpcError error;

  @override
  String toString() {
    return 'RpcException: ${error.error}';
  }
}

class RpcError extends Equatable {
  const RpcError({
    this.mmrpc,
    this.error,
    this.errorPath,
    this.errorTrace,
    this.errorType,
    this.errorData,
    this.id,
  });

  factory RpcError.fromJson(Map<String, dynamic> json) => RpcError(
        mmrpc: json['mmrpc'] as String?,
        error: json['error'] as String?,
        errorPath: json['error_path'] as String?,
        errorTrace: json['error_trace'] as String?,
        errorType: RpcErrorType.fromString(json['error_type'] as String? ?? ''),
        errorData: json['error_data'] as String?,
        id: json['id'] as int?,
      );

  final String? mmrpc;
  final String? error;
  final String? errorPath;
  final String? errorTrace;
  final RpcErrorType? errorType;
  final String? errorData;
  final int? id;

  Map<String, dynamic> toJson() => {
        'mmrpc': mmrpc,
        'error': error,
        'error_path': errorPath,
        'error_trace': errorTrace,
        'error_type': errorType?.toString(),
        'error_data': errorData,
        'id': id,
      };

  RpcError copyWith({
    String? mmrpc,
    String? error,
    String? errorPath,
    String? errorTrace,
    RpcErrorType? errorType,
    String? errorData,
    int? id,
  }) {
    return RpcError(
      mmrpc: mmrpc ?? this.mmrpc,
      error: error ?? this.error,
      errorPath: errorPath ?? this.errorPath,
      errorTrace: errorTrace ?? this.errorTrace,
      errorType: errorType ?? this.errorType,
      errorData: errorData ?? this.errorData,
      id: id ?? this.id,
    );
  }

  @override
  String toString() {
    return '''
RpcError: {
  mmrpc: $mmrpc, 
  error: $error, 
  errorPath: $errorPath, 
  errorTrace: $errorTrace, 
  errorType: $errorType,
  errorData: $errorData, 
  id: $id
}''';
  }

  @override
  List<Object?> get props {
    return [
      mmrpc,
      error,
      errorPath,
      errorTrace,
      errorType,
      errorData,
      id,
    ];
  }
}
