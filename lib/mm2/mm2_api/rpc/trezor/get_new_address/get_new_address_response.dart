import 'package:komodo_wallet/model/hd_account/hd_account.dart';

class TrezorGetNewAddressInitResponse {
  TrezorGetNewAddressInitResponse({this.result, this.error});

  factory TrezorGetNewAddressInitResponse.fromJson(Map<String, dynamic> json) {
    return TrezorGetNewAddressInitResponse(
      result: TrezorGetNewAddressInitResult.fromJson(json['result']),
      error: json['error'],
    );
  }

  final TrezorGetNewAddressInitResult? result;
  final dynamic error;
}

class TrezorGetNewAddressInitResult {
  TrezorGetNewAddressInitResult({required this.taskId});

  static TrezorGetNewAddressInitResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return TrezorGetNewAddressInitResult(
      taskId: json['task_id'],
    );
  }

  final int taskId;
}

class GetNewAddressResponse {
  GetNewAddressResponse({
    this.result,
    this.error,
  });

  factory GetNewAddressResponse.fromJson(Map<String, dynamic> json) {
    return GetNewAddressResponse(
      result: GetNewAddressResult.fromJson(json['result']),
      error: json['error'],
    );
  }

  final String? error;
  final GetNewAddressResult? result;
}

class GetNewAddressResult {
  GetNewAddressResult({required this.status, required this.details});

  static GetNewAddressResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final GetNewAddressStatus status =
        GetNewAddressStatus.fromString(json['status']);
    final GetNewAddressResultDetails? details =
        _getDetails(status, json['details']);
    return GetNewAddressResult(
      status: status,
      details: details,
    );
  }

  final GetNewAddressStatus status;
  final GetNewAddressResultDetails? details;
}

GetNewAddressResultDetails? _getDetails(
  GetNewAddressStatus status,
  dynamic json,
) {
  if (json == null) return null;

  switch (status) {
    case GetNewAddressStatus.ok:
      final Map<String, dynamic>? newAddressJson = json['new_address'];
      if (newAddressJson == null) return null;

      return GetNewAddressResultOkDetails(
          newAddress: HdAddress.fromJson(newAddressJson));
    case GetNewAddressStatus.inProgress:
      if (json is! Map<String, dynamic>) return null;
      final confirmAddressJson = json['ConfirmAddress'];
      if (confirmAddressJson != null) {
        return GetNewAddressResultConfirmAddressDetails(
            expectedAddress: confirmAddressJson['expected_address']);
      }

      final requestingAccountBalanceJson = json['RequestingAccountBalance'];
      if (requestingAccountBalanceJson != null) {
        return const GetNewAddressResultRequestingAccountBalanceDetails();
      }
      return null;
    case GetNewAddressStatus.unknown:
      return null;
  }
}

enum GetNewAddressStatus {
  ok,
  inProgress,
  unknown;

  factory GetNewAddressStatus.fromString(String status) {
    switch (status) {
      case 'Ok':
        return GetNewAddressStatus.ok;
      case 'InProgress':
        return GetNewAddressStatus.inProgress;
    }
    return GetNewAddressStatus.unknown;
  }
}

abstract class GetNewAddressResultDetails {
  const GetNewAddressResultDetails();
}

class GetNewAddressResultConfirmAddressDetails
    extends GetNewAddressResultDetails {
  const GetNewAddressResultConfirmAddressDetails(
      {required this.expectedAddress});

  final String expectedAddress;
}

class GetNewAddressResultRequestingAccountBalanceDetails
    extends GetNewAddressResultDetails {
  const GetNewAddressResultRequestingAccountBalanceDetails();
}

class GetNewAddressResultOkDetails extends GetNewAddressResultDetails {
  const GetNewAddressResultOkDetails({required this.newAddress});
  final HdAddress newAddress;
}
