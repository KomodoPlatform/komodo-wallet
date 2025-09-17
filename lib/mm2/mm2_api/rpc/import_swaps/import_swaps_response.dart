import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class ImportSwapsResponseResult {
  ImportSwapsResponseResult({required this.imported, required this.skipped});

  factory ImportSwapsResponseResult.fromJson(Map<String, dynamic> json) =>
      ImportSwapsResponseResult(
        imported: List<String>.from(json['imported'] ?? <String>[]),
        skipped: Map.from(json['skipped'] ?? <String, String>{}),
      );

  final List<String> imported;
  final Map<String, String> skipped;
}

class ImportSwapsResponse implements BaseResponse<ImportSwapsResponseResult> {
  ImportSwapsResponse({required this.result});

  factory ImportSwapsResponse.fromJson(Map<String, dynamic> json) =>
      ImportSwapsResponse(
        result: ImportSwapsResponseResult.fromJson(json['result']),
      );

  @override
  final String mmrpc = '';
  @override
  final ImportSwapsResponseResult result;
}
