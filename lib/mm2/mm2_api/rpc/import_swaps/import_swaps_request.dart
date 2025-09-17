import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class ImportSwapsRequest implements BaseRequest {
  ImportSwapsRequest({this.swaps = const <dynamic>[]});
  @override
  late String userpass;
  @override
  final String method = 'import_swaps';
  final List<dynamic> swaps;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'userpass': userpass,
    'method': method,
    'swaps': swaps,
  };
}
