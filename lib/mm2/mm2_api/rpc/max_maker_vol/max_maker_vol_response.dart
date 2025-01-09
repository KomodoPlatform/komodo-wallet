class MaxMakerVolResponse {
  MaxMakerVolResponse({
    required this.volume,
    required this.balance,
  });

  final MaxMakerVolResponseValue volume;
  final MaxMakerVolResponseValue balance;

  factory MaxMakerVolResponse.fromJson(Map<String, dynamic> json) =>
      MaxMakerVolResponse(
        volume: MaxMakerVolResponseValue.fromJson(json['volume']),
        balance: MaxMakerVolResponseValue.fromJson(json['balance']),
      );
}

class MaxMakerVolResponseValue {
  MaxMakerVolResponseValue({
    required this.decimal,
  });

  final String decimal;

  factory MaxMakerVolResponseValue.fromJson(Map<String, dynamic> json) =>
      MaxMakerVolResponseValue(decimal: json['decimal']);

  Map<String, String> toJson() => <String, String>{
        'decimal': decimal,
      };
}
