import 'package:komodo_wallet/mm2/mm2_api/rpc/withdraw/fee/fee_request.dart';
import 'package:komodo_wallet/model/coin.dart';

class TrezorWithdrawRequest {
  TrezorWithdrawRequest({
    required this.coin,
    required this.from,
    required this.to,
    required this.amount,
    this.max = false,
    this.fee,
  });

  static const String method = 'task::withdraw::init';
  late String userpass;
  final Coin coin;
  final String to;
  final String from;
  final double amount;
  final bool max;
  final FeeRequest? fee;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'userpass': userpass,
      'mmrpc': '2.0',
      'params': {
        'coin': coin.abbr,
        'from': {
          'derivation_path': coin.getDerivationPath(from),
        },
        'to': to,
        'amount': amount,
        'max': max,
        if (fee != null) 'fee': fee!.toJson(),
      }
    };
  }
}
