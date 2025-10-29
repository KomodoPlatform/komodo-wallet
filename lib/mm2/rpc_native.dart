import 'package:http/http.dart' as http;
import 'package:web_dex/mm2/rpc.dart';

class RPCNative extends RPC {
  RPCNative({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final Uri _url = Uri.parse('http://localhost:7783');
  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<dynamic> call(String reqStr) async {
    // todo: implement error handling
    final http.Response response = await _client.post(_url, body: reqStr);
    return response.body;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
