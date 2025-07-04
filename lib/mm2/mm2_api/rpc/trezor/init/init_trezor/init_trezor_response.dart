import 'package:komodo_wallet/model/hw_wallet/init_trezor.dart';

class InitTrezorRes {
  InitTrezorRes({
    this.result,
    this.error,
    this.id,
  });

  factory InitTrezorRes.fromJson(Map<String, dynamic> json) {
    return InitTrezorRes(
        result: InitTrezorResult.fromJson(json['result']),
        error: json['error'],
        id: json['id']);
  }

  final InitTrezorResult? result;
  final String? error;
  final String? id;
}
