import 'package:web_dex/model/swap.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

class MyRecentSwapsResponse {
  MyRecentSwapsResponse({required this.result});

  factory MyRecentSwapsResponse.fromJson(JsonMap json) => MyRecentSwapsResponse(
    result: MyRecentSwapsResponseResult.fromJson(json.value<JsonMap>('result')),
  );

  MyRecentSwapsResponseResult result;

  JsonMap get toJson => <String, dynamic>{'result': result.toJson};
}

class MyRecentSwapsResponseResult {
  MyRecentSwapsResponseResult({
    required this.fromUuid,
    required this.limit,
    required this.skipped,
    required this.swaps,
    required this.total,
    required this.pageNumber,
    required this.foundRecords,
    required this.totalPages,
  });

  factory MyRecentSwapsResponseResult.fromJson(JsonMap json) =>
      MyRecentSwapsResponseResult(
        fromUuid: json.valueOrNull<String>('from_uuid'),
        limit: json.value<int>('limit'),
        skipped: json.value<int>('skipped'),
        swaps: json
            .value<List<JsonMap>>('swaps')
            .where((JsonMap x) => x.isNotEmpty)
            .map((JsonMap x) => Swap.fromJson(x))
            .toList(),
        total: json.value<int>('total'),
        foundRecords: json.value<int>('found_records'),
        pageNumber: json.value<int>('page_number'),
        totalPages: json.value<int>('total_pages'),
      );

  String? fromUuid;
  int limit;
  int skipped;
  List<Swap> swaps;
  int total;
  int pageNumber;
  int totalPages;
  int foundRecords;

  JsonMap get toJson => <String, dynamic>{
    'from_uuid': fromUuid,
    'limit': limit,
    'skipped': skipped,
    'swaps': List<dynamic>.from(swaps.map<JsonMap>((Swap x) => x.toJson())),
    'total': total,
  };
}
