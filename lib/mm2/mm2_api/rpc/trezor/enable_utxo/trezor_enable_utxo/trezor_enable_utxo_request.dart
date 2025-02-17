import 'package:komodo_defi_types/komodo_defi_types.dart';

class TrezorEnableUtxoReq {
  TrezorEnableUtxoReq({required this.coin});

  static const String method = 'task::enable_utxo::init';
  late String userpass;
  final Asset coin;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'userpass': userpass,
      'mmrpc': '2.0',
      'params': {
        'ticker': coin.id.id,
        'activation_params': {
          'tx_history': true,
          'mode': {
            'rpc': 'Electrum',
            'rpc_data': {
              'servers': coin.protocol.requiredServers.electrum!
                  .map((server) => server.toJsonRequest())
                  .toList(),
            },
          },
          'scan_policy': 'scan_if_new_wallet',
          'priv_key_policy': 'Trezor'
        }
      }
    };
  }
}
