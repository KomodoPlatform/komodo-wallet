class GetEnabledCoinsReq {
  static const String method = 'get_enabled_coins';
  late String userpass;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'userpass': userpass,
    };
  }
}
