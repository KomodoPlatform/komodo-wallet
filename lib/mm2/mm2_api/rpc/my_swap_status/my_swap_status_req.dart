class MySwapStatusReq {
  MySwapStatusReq({required this.uuid});

  final String method = 'my_swap_status';
  late String userpass;
  final String uuid;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'method': method,
    'params': {'uuid': uuid},
    'userpass': userpass,
  };
}
