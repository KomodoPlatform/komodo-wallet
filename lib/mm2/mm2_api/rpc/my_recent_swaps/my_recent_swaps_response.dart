import 'package:web_dex/model/swap.dart';

class MyRecentSwapsResponse {
  MyRecentSwapsResponse({required this.result});

  factory MyRecentSwapsResponse.fromJson(Map<String, dynamic> json) =>
      MyRecentSwapsResponse(
        result: MyRecentSwapsResponseResult.fromJson(
          Map<String, dynamic>.from(json['result'] as Map? ?? {}),
        ),
      );

  MyRecentSwapsResponseResult result;

  Map<String, dynamic> get toJson => <String, dynamic>{'result': result.toJson};
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

  factory MyRecentSwapsResponseResult.fromJson(Map<String, dynamic> json) =>
      MyRecentSwapsResponseResult(
        fromUuid: json['from_uuid'] as String?,
        limit: json['limit'] as int? ?? 0,
        skipped: json['skipped'] as int? ?? 0,
        swaps: List<Swap>.from(
          (json['swaps'] as List? ?? <Swap>[])
              .where((dynamic x) => x != null)
              .map(
                (dynamic x) => Swap.fromJson(x as Map<String, dynamic>? ?? {}),
              ),
        ),
        total: json['total'] as int? ?? 0,
        foundRecords: json['found_records'] as int? ?? 0,
        pageNumber: json['page_number'] as int? ?? 0,
        totalPages: json['total_pages'] as int? ?? 0,
      );

  String? fromUuid;
  int limit;
  int skipped;
  List<Swap> swaps;
  int total;
  int pageNumber;
  int totalPages;
  int foundRecords;

  Map<String, dynamic> get toJson => <String, dynamic>{
    'from_uuid': fromUuid,
    'limit': limit,
    'skipped': skipped,
    'swaps': List<dynamic>.from(
      swaps.map<Map<String, dynamic>>((Swap x) => x.toJson()),
    ),
    'total': total,
  };
}
