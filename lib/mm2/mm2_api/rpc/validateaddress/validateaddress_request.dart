import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class ValidateAddressRequest implements BaseRequest {
  ValidateAddressRequest({
    required this.coin,
    required this.address,
  });

  @override
  final String method = 'validateaddress';
  String address;
  String coin;

  @override
  late String userpass;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'coin': coin,
      'userpass': userpass,
      'address': address,
    };
  }
}
