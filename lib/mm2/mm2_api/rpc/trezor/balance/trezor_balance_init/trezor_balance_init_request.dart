import 'package:komodo_wallet/model/coin.dart';

class TrezorBalanceInitRequest {
  TrezorBalanceInitRequest({
    required this.coin,
  });

  static const String method = 'task::account_balance::init';
  late String userpass;
  final Coin coin;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'userpass': userpass,
      'mmrpc': '2.0',
      'params': {'coin': coin.abbr, 'account_index': 0}
    };
  }
}
