import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class EnableTendermintTokenRequest
    implements
        BaseRequest,
        BaseRequestWithParams<EnableTendermintTokenRequestParams> {
  EnableTendermintTokenRequest({required String ticker})
      : params = EnableTendermintTokenRequestParams(
          ticker: ticker,
        );
  @override
  late String userpass;
  @override
  final method = 'enable_tendermint_token';
  @override
  final EnableTendermintTokenRequestParams params;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mmrpc': '2.0',
      'method': method,
      'userpass': userpass,
      'params': params.toJson(),
    };
  }
}

class EnableTendermintTokenRequestParams {
  EnableTendermintTokenRequestParams({required this.ticker});
  final String ticker;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ticker': ticker,
      'tx_history': true,
      'activation_params': <String, dynamic>{},
    };
  }
}
