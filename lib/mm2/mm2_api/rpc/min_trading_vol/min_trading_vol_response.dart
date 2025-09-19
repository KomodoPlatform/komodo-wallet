class MinTradingVolResponse {
  MinTradingVolResponse({
    required this.coin,
    required this.result,
  });

  factory MinTradingVolResponse.fromJson(Map<String, dynamic> json) =>
      MinTradingVolResponse(
        coin: json['coin'] ?? '',
        result: MinTradingVolResponseResult.fromJson(json['result']),
      );

  final String coin;
  final MinTradingVolResponseResult result;
}

class MinTradingVolResponseResult {
  MinTradingVolResponseResult({
    required this.numer,
    required this.denom,
  });

  factory MinTradingVolResponseResult.fromJson(Map<String, dynamic> json) {
    return MinTradingVolResponseResult(
      denom: json['min_trading_vol_fraction']['denom'],
      numer: json['min_trading_vol_fraction']['numer'],
    );
  }

  final String denom;
  final String numer;

  Map<String, String> toJson() => <String, String>{
        'denom': denom,
        'numer': numer,
      };
}
