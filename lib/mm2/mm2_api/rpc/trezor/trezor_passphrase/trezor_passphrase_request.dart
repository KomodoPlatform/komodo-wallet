import 'package:komodo_wallet/model/hw_wallet/trezor_task.dart';

class TrezorPassphraseRequest {
  TrezorPassphraseRequest({required this.passphrase, required this.task});

  final String passphrase;
  final TrezorTask task;
  late String userpass;

  String get method => 'task::${task.type.name}::user_action';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'userpass': userpass,
      'mmrpc': '2.0',
      'params': {
        'task_id': task.taskId,
        'user_action': {
          'action_type': 'TrezorPassphrase',
          'passphrase': passphrase,
        }
      },
      'id': null
    };
  }
}
