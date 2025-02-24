class MaxMakerVolResponse {
  MaxMakerVolResponse({
    required this.volume,
    required this.balance,
  });

  factory MaxMakerVolResponse.fromJson(Map<String, dynamic> json) =>
      MaxMakerVolResponse(
        volume: MaxMakerVolResponseValue.fromJson(
          Map<String, dynamic>.from(json['volume'] as Map? ?? {}),
        ),
        balance: MaxMakerVolResponseValue.fromJson(
          Map<String, dynamic>.from(json['balance'] as Map? ?? {}),
        ),
      );

  final MaxMakerVolResponseValue volume;
  final MaxMakerVolResponseValue balance;
}

class MaxMakerVolResponseValue {
  MaxMakerVolResponseValue({
    required this.decimal,
  });

  factory MaxMakerVolResponseValue.fromJson(Map<String, dynamic> json) =>
      MaxMakerVolResponseValue(decimal: json['decimal'] as String);

  final String decimal;

  Map<String, String> toJson() => <String, String>{
        'decimal': decimal,
      };
}
