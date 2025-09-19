class DisableCoinReq {
  DisableCoinReq({
    required this.coin,
  });

  static const String method = 'disable_coin';
  final String coin;
  late String userpass;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'coin': coin,
      'userpass': userpass,
    };
  }
}
