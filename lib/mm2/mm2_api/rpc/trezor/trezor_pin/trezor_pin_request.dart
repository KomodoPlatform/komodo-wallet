import 'package:komodo_wallet/model/hw_wallet/trezor_task.dart';

class TrezorPinRequest {
  TrezorPinRequest({required this.pin, required this.task});

  final String pin;
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
          'action_type': 'TrezorPin',
          'pin': pin,
        }
      },
      'id': null
    };
  }
}
