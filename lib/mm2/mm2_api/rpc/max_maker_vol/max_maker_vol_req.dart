class MaxMakerVolRequest {
  MaxMakerVolRequest({
    required this.coin,
  });

  static const String method = 'max_maker_vol';
  final String coin;
  late String userpass;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'mmrpc': '2.0',
      'userpass': userpass,
      'params': {
        'coin': coin,
      },
    };
  }
}
