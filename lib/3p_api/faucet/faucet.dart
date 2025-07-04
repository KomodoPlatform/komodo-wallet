import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:komodo_wallet/3p_api/faucet/faucet_response.dart';

Future<FaucetResponse> callFaucet(String coin, String address) async {
  try {
    final response = await http.get(
      Uri.parse('https://faucet.komodo.earth/faucet/$coin/$address'),
    );

    final Map<String, dynamic> json = jsonDecode(response.body);
    return FaucetResponse.fromJson(json);
  } catch (e) {
    return FaucetResponse.error(e.toString());
  }
}
