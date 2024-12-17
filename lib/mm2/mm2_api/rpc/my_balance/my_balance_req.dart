class MyBalanceReq {
  MyBalanceReq({
    required this.coin,
  });

  static const String method = 'my_balance';
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
