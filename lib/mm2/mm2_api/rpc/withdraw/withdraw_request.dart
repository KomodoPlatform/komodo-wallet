import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/fee/fee_request.dart';

class WithdrawRequestParams {
  WithdrawRequestParams({
    required this.coin,
    required this.to,
    this.amount,
    this.max,
    this.memo,
    this.fee,
  });

  String? amount;
  String coin;
  String to;
  bool? max;
  String? memo;
  FeeRequest? fee;
}

class WithdrawRequest
    implements BaseRequest, BaseRequestWithParams<WithdrawRequestParams> {
  WithdrawRequest({
    String? amount,
    required String to,
    required String coin,
    required bool max,
    String? memo,
    FeeRequest? fee,
  }) : params = WithdrawRequestParams(
          amount: amount,
          to: to,
          coin: coin,
          max: max,
          fee: fee,
          memo: memo,
        );

  @override
  final String method = 'withdraw';
  @override
  final WithdrawRequestParams params;
  @override
  late String userpass;

  @override
  Map<String, dynamic> toJson() {
    final FeeRequest? fee = params.fee;

    return <String, dynamic>{
      'method': method,
      'userpass': userpass,
      'mmrpc': mmRpcVersion,
      'params': {
        'to': params.to,
        'max': params.max ?? false,
        'coin': params.coin,
        if (params.memo != null) 'memo': params.memo,
        if (params.amount != null) 'amount': params.amount,
        if (fee != null) 'fee': fee.toJson(),
      },
    };
  }
}
