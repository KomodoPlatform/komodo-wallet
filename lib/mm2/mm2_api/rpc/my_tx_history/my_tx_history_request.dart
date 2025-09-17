import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class MyTxHistoryRequest implements BaseRequest {
  MyTxHistoryRequest({
    required this.coin,
    required this.max,
    this.limit,
    this.fromId,
    this.pageNumber,
  });

  @override
  final String method = 'my_tx_history';
  @override
  late String userpass;

  final String coin;
  final bool max;
  final String? fromId;
  final int? limit;
  final int? pageNumber;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'method': method,
    'userpass': userpass,
    'coin': coin,
    'max': max,
    if (fromId != null) 'from_id': fromId,
    if (pageNumber != null) 'page_number': pageNumber,
    if (limit != null) 'limit': limit,
  };
}
