abstract class BaseRequest {
  final String method = '';
  late String userpass;

  Map<String, dynamic> toJson();
}

abstract class BaseRequestWithParams<T> {
  BaseRequestWithParams(this.params);

  final T params;
}

abstract class BaseResponse<T> {
  BaseResponse({required this.result});

  final String mmrpc = '';
  final T result;
}

abstract class BaseError implements Exception {
  const BaseError();
  String get message;
}

abstract class ErrorNeedSetExtraData<T> {
  void setExtraData(T data);
}

abstract mixin class ErrorWithDetails {
  String get details;
}

abstract class ErrorFactory<T> {
  ErrorFactory();
  BaseError getError(Map<String, dynamic> json, T data);
}

class ApiResponse<Req, Res, E> {
  ApiResponse({required this.request, this.result, this.error});
  final Req request;
  final Res? result;
  final E? error;
}
