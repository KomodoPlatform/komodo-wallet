import 'package:komodo_wallet/model/hd_account/hd_account.dart';
import 'package:komodo_wallet/model/hw_wallet/init_trezor.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_status.dart';

class TrezorEnableUtxoStatusResponse {
  TrezorEnableUtxoStatusResponse({this.result, this.error});

  static TrezorEnableUtxoStatusResponse fromJson(Map<String, dynamic> json) {
    return TrezorEnableUtxoStatusResponse(
        result: TrezorEnableUtxoStatusResult.fromJson(json['result']));
  }

  final TrezorEnableUtxoStatusResult? result;
  final dynamic error;
}

class TrezorEnableUtxoStatusResult {
  TrezorEnableUtxoStatusResult({
    required this.status,
    this.details,
    this.actionDetails,
  });

  static TrezorEnableUtxoStatusResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final InitTrezorStatus status = InitTrezorStatus.fromJson(json['status']);
    return TrezorEnableUtxoStatusResult(
        status: status,
        details: status == InitTrezorStatus.ok
            ? TrezorEnableDetails.fromJson(json['details'])
            : null,
        actionDetails: status == InitTrezorStatus.userActionRequired
            ? TrezorUserAction.fromJson(json['details'])
            : null);
  }

  final InitTrezorStatus status;
  final TrezorEnableDetails? details;
  final TrezorUserAction? actionDetails;
}

class TrezorEnableDetails {
  TrezorEnableDetails({
    required this.accounts,
  });

  static TrezorEnableDetails? fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic>? jsonData = json?['wallet_balance'];
    if (jsonData == null) return null;

    return TrezorEnableDetails(
        accounts: jsonData['accounts']
            .map<HdAccount>((dynamic item) => HdAccount.fromJson(item))
            .toList());
  }

  final List<HdAccount> accounts;
}
