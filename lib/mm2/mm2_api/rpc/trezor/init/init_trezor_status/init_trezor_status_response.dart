import 'package:komodo_wallet/model/hw_wallet/init_trezor.dart';

class InitTrezorStatusRes {
  InitTrezorStatusRes({
    this.result,
    this.error,
    this.errorType,
    this.id,
  });

  factory InitTrezorStatusRes.fromJson(Map<String, dynamic> json) {
    return InitTrezorStatusRes(
        result: InitTrezorStatusData.fromJson(json['result']),
        error: json['error'],
        errorType: json['error_type'],
        id: json['id']);
  }

  final InitTrezorStatusData? result;
  final String? error;
  final String? errorType;
  final String? id;
}
