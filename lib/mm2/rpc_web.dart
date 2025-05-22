import 'dart:js_interop';
import 'package:web_dex/mm2/rpc.dart';
import 'package:web_dex/platform/platform.dart';

class RPCWeb extends RPC {
  const RPCWeb();

  @override
  Future<dynamic> call(String reqStr) async {
    final dynamic response = await wasmRpc(reqStr.toJS).toDart;
    return response;
  }
}
