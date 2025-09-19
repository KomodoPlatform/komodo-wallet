class MaxMakerVolResponse {
  MaxMakerVolResponse({
    required this.coin,
    required this.volume,
    required this.balance,
  });

  factory MaxMakerVolResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;
    if (result == null) {
      throw ArgumentError.value(
        json,
        'json',
        'Expected a non-null result field in MaxMakerVolResponse',
      );
    }

    return MaxMakerVolResponse(
      coin: result['coin'] as String? ?? '',
      volume: MaxMakerVolResponseValue.fromJson(
        Map<String, dynamic>.from(result['volume'] as Map? ?? {}),
      ),
      balance: MaxMakerVolResponseValue.fromJson(
        Map<String, dynamic>.from(result['balance'] as Map? ?? {}),
      ),
    );
  }

  final String coin;
  final MaxMakerVolResponseValue volume;
  final MaxMakerVolResponseValue balance;
}

class MaxMakerVolResponseValue {
  MaxMakerVolResponseValue({
    required this.decimal,
    required this.numer,
    required this.denom,
  });

  factory MaxMakerVolResponseValue.fromJson(Map<String, dynamic> json) {
    final fraction = json['fraction'] as Map<String, dynamic>?;
    if (fraction == null) {
      throw ArgumentError.value(
        json,
        'json',
        'Expected a non-null fraction field in MaxMakerVolResponseValue',
      );
    }

    return MaxMakerVolResponseValue(
      decimal: json['decimal'] as String? ?? '',
      numer: fraction['numer'] as String,
      denom: fraction['denom'] as String,
    );
  }

  final String decimal;
  final String numer;
  final String denom;

  Map<String, String> toFractionalJson() => <String, String>{
        'numer': numer,
        'denom': denom,
      };
}
