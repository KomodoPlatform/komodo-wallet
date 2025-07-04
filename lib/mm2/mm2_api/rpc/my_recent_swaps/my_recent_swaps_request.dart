import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class MyRecentSwapsRequest implements BaseRequest {
  MyRecentSwapsRequest({
    this.fromUuid,
    this.pageNumber,
    this.myCoin,
    this.otherCoin,
    this.fromTimestamp,
    this.toTimestamp,
    this.limit = 10000,
  });

  final int? limit;
  final String? fromUuid;
  final int? pageNumber;
  final String? myCoin;
  final String? otherCoin;
  final int? fromTimestamp;
  final int? toTimestamp;

  @override
  late String userpass;
  @override
  final String method = 'my_recent_swaps';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'userpass': userpass,
        'method': method,
        'from_uuid': fromUuid,
        if (limit != null) 'limit': limit,
        if (pageNumber != null) 'page_number': pageNumber,
        'my_coin': myCoin,
        'other_coin': otherCoin,
        'from_timestamp': fromTimestamp,
        'to_timestamp': toTimestamp,
      };
}
