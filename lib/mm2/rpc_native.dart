import 'package:http/http.dart';
import 'package:web_dex/mm2/rpc.dart';

class RPCNative extends RPC {
  RPCNative();

  final Uri _url = Uri.parse('http://127.0.0.1:7783');
  final Client client = Client();

  @override
  Future<dynamic> call(String reqStr) async {
    // todo: implement error handling
    final Response response = await client.post(_url, body: reqStr);
    return response.body;
  }
}
