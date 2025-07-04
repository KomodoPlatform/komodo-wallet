import 'package:komodo_wallet/model/hw_wallet/trezor_progress_status.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_status.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_status_error.dart';

class InitTrezorResult {
  InitTrezorResult({required this.taskId});

  static InitTrezorResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return InitTrezorResult(taskId: json['task_id']);
  }

  final int taskId;
}

class InitTrezorStatusData {
  InitTrezorStatusData({
    required this.trezorStatus,
    required this.details,
  });

  static InitTrezorStatusData? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final status = InitTrezorStatus.fromJson(json['status']);
    return InitTrezorStatusData(
        trezorStatus: status,
        details: TrezorStatusDetails.fromJson(
          json['details'],
          status,
        ));
  }

  final InitTrezorStatus trezorStatus;
  final TrezorStatusDetails details;
}

class TrezorStatusDetails {
  TrezorStatusDetails({
    this.progressDetails,
    this.details,
    this.errorDetails,
    this.actionDetails,
    this.deviceDetails,
  });

  factory TrezorStatusDetails.fromJson(dynamic json, InitTrezorStatus status) {
    switch (status) {
      case InitTrezorStatus.inProgress:
        return TrezorStatusDetails(
          progressDetails: TrezorProgressStatus.fromJson(json),
        );
      case InitTrezorStatus.userActionRequired:
        return TrezorStatusDetails(
          actionDetails: TrezorUserAction.fromJson(json),
        );
      case InitTrezorStatus.ok:
        return TrezorStatusDetails(
            deviceDetails: TrezorDeviceDetails.fromJson(json));
      case InitTrezorStatus.error:
        return TrezorStatusDetails(
            errorDetails: TrezorStatusError.fromJson(json));
      default:
        return TrezorStatusDetails(details: json);
    }
  }

  final dynamic details;
  final TrezorProgressStatus? progressDetails;
  final TrezorStatusError? errorDetails;
  final TrezorUserAction? actionDetails;
  final TrezorDeviceDetails? deviceDetails;
}

class TrezorDeviceDetails {
  TrezorDeviceDetails({
    required this.pubKey,
    this.name,
    this.deviceId,
  });

  static TrezorDeviceDetails fromJson(Map<String, dynamic> json) {
    return TrezorDeviceDetails(
      pubKey: json['device_pubkey'],
      name: json['device_name'],
      deviceId: json['device_id'],
    );
  }

  final String pubKey;
  final String? name;
  final String? deviceId;
}

enum TrezorUserAction {
  enterTrezorPin,
  enterTrezorPassphrase,
  unknown;

  static TrezorUserAction fromJson(String json) {
    switch (json) {
      case 'EnterTrezorPin':
        return TrezorUserAction.enterTrezorPin;
      case 'EnterTrezorPassphrase':
        return TrezorUserAction.enterTrezorPassphrase;
      default:
        return TrezorUserAction.unknown;
    }
  }
}
