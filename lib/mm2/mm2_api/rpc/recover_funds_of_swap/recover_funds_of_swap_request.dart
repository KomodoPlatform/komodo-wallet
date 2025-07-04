import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class RecoverFundsOfSwapRequest implements BaseRequest {
  RecoverFundsOfSwapRequest({required this.uuid});

  final String uuid;
  @override
  late String userpass;
  @override
  final String method = 'recover_funds_of_swap';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'userpass': userpass,
        'method': method,
        'params': {
          'uuid': uuid,
        },
      };
}
