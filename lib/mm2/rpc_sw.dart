import 'dart:async';

import 'package:universal_html/js.dart';
import 'package:web_dex/mm2/rpc.dart';

class RPCSw extends RPC {
  const RPCSw();

  @override
  Future<dynamic> call(String reqStr) async {
    final dynamic response = await sendMessage<dynamic>({
      'action': 'rpc_request',
      'request': reqStr,
    });

    return response;
  }
}

Future<T> sendMessage<T>(Map<String, dynamic> message) {
  final completer = Completer<T>();

  context['chrome']['runtime'].callMethod('sendMessage', [
    JsObject.jsify(message),
    (response) {
      completer.complete(response);
      // if (response != null && response is Map && response['error'] != null) {
      //   completer.completeError(response['error']);
      // } else {
      //   completer.complete(response);
      // }
    }
  ]);

  return completer.future;
}
