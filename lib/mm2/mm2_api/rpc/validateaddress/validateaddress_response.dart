class ValidateAddressResponse {
  ValidateAddressResponse({required this.isValid, this.reason});

  factory ValidateAddressResponse.fromJson(Map<String, dynamic> response) {
    return ValidateAddressResponse(
      isValid: response['result']?['is_valid'] ?? false,
      reason: response['result']?['reason'],
    );
  }
  final bool isValid;
  final String? reason;
}
