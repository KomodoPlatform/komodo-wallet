import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class VersionRequest implements BaseRequest {
  @override
  late String userpass;

  @override
  String method = 'version';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'method': method,
    'userpass': userpass,
  };
}
