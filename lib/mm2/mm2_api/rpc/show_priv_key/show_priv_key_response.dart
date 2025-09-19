class ShowPrivKeyResponse {
  ShowPrivKeyResponse({
    required this.coin,
    required this.privKey,
  });

  factory ShowPrivKeyResponse.fromJson(Map<String, dynamic> json) =>
      ShowPrivKeyResponse(
        coin: json['result']['coin'] ?? '',
        privKey: json['result']['priv_key'] ?? '',
      );
  final String coin;
  final String privKey;
}
