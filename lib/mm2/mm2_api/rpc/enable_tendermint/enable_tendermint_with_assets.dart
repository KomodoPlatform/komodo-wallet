import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';
import 'package:komodo_wallet/model/coin.dart';

class EnableTendermintWithAssetsRequest
    implements
        BaseRequest,
        BaseRequestWithParams<EnableTendermintWithAssetsRequestParams> {
  EnableTendermintWithAssetsRequest({
    required String ticker,
    required List<CoinNode> rpcUrls,
    List<TendermintTokenParamsItem> tokensParams = const [],
  }) : params = EnableTendermintWithAssetsRequestParams(
            ticker: ticker, tokensParams: tokensParams, rpcUrls: rpcUrls);
  @override
  late String userpass;
  @override
  final method = 'enable_tendermint_with_assets';
  @override
  final EnableTendermintWithAssetsRequestParams params;

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

class EnableTendermintWithAssetsRequestParams {
  EnableTendermintWithAssetsRequestParams({
    required this.ticker,
    required this.tokensParams,
    required this.rpcUrls,
  });
  final String ticker;
  final List<CoinNode> rpcUrls;
  final List<TendermintTokenParamsItem> tokensParams;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tokens_params': tokensParams,
      'rpc_urls': rpcUrls.map((e) => e.url).toList(),
      'ticker': ticker,
      'tx_history': true,
    };
  }
}

class TendermintTokenParamsItem {
  const TendermintTokenParamsItem({required this.ticker});
  final String ticker;
}
