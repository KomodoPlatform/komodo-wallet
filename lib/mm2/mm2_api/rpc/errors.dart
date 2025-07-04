import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class ApiError implements BaseError {
  const ApiError({required this.message});

  @override
  final String message;
}

class TransportError implements BaseError {
  const TransportError({required this.message});
  @override
  final String message;
}

class ParsingApiJsonError implements BaseError {
  const ParsingApiJsonError({required this.message});
  @override
  final String message;
}
