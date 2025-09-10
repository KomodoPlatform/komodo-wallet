class StopReq {
  StopReq();

  static const String method = 'stop';
  late String userpass;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'method': method, 'userpass': userpass, 'mm2': 1};
  }
}
