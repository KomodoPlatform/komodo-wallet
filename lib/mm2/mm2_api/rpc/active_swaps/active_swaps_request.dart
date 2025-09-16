class ActiveSwapsRequest {
  ActiveSwapsRequest({this.method = 'active_swaps'});

  final String method;
  late String userpass;
  final bool includeStatus = true;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userpass': userpass,
        'method': method,
        'include_status': true
      };
}
