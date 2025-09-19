class VersionResponse {
  const VersionResponse({required this.result});
  factory VersionResponse.fromJson(Map<String, dynamic> response) {
    return VersionResponse(
      result: response['result'] ?? '',
    );
  }
  final String result;
}
