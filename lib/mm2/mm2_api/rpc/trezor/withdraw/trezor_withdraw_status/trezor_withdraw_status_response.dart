import 'package:komodo_wallet/model/hw_wallet/init_trezor.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_progress_status.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_status.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_status_error.dart';
import 'package:komodo_wallet/model/withdraw_details/withdraw_details.dart';

class TrezorWithdrawStatusResponse {
  TrezorWithdrawStatusResponse({this.result, this.error});

  factory TrezorWithdrawStatusResponse.fromJson(Map<String, dynamic> json) {
    return TrezorWithdrawStatusResponse(
        result: TrezorWithdrawStatusResult.fromJson(json['result']),
        error: json['error']);
  }

  final TrezorWithdrawStatusResult? result;
  final String? error;
}

class TrezorWithdrawStatusResult {
  TrezorWithdrawStatusResult({
    required this.status,
    this.details,
    this.progressDetails,
    this.actionDetails,
    this.errorDetails,
  });

  final InitTrezorStatus status;
  final WithdrawDetails? details;
  final TrezorProgressStatus? progressDetails;
  final TrezorUserAction? actionDetails;
  final TrezorStatusError? errorDetails;

  static TrezorWithdrawStatusResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final InitTrezorStatus status = InitTrezorStatus.fromJson(json['status']);

    return TrezorWithdrawStatusResult(
      status: status,
      details: status == InitTrezorStatus.ok
          ? WithdrawDetails.fromTrezorJson(json['details'])
          : null,
      progressDetails: status == InitTrezorStatus.inProgress
          ? TrezorProgressStatus.fromJson(json['details'])
          : null,
      actionDetails: status == InitTrezorStatus.userActionRequired
          ? TrezorUserAction.fromJson(json['details'])
          : null,
      errorDetails: status == InitTrezorStatus.error
          ? TrezorStatusError.fromJson(json['details'])
          : null,
    );
  }
}
