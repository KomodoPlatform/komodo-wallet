enum PaymentStatusType {
  widgetClose('WIDGET_CLOSE'),
  widgetConfigDone('WIDGET_CONFIG_DONE'),
  widgetConfigFailed('WIDGET_CONFIG_FAILED'),
  widgetCloseRequest('WIDGET_CLOSE_REQUEST'),
  widgetCloseRequestCancelled('WIDGET_CLOSE_REQUEST_CANCELLED'),
  widgetCloseRequestConfirmed('WIDGET_CLOSE_REQUEST_CONFIRMED'),
  purchaseCreated('PURCHASE_CREATED'),
  offrampSaleCreated('OFFRAMP_SALE_CREATED'),
  paymentStatus('PAYMENT-STATUS');

  const PaymentStatusType(this.value);

  final String value;

  /// Creates a RampWidgetStatusEvents from a JSON input
  static PaymentStatusType fromJson(Map<String, dynamic> json) {
    try {
      String typeValue;

      if (json.containsKey('type')) {
        typeValue = json['type'] as String;
      } else {
        throw const FormatException('Missing "type" field in JSON object');
      }

      return PaymentStatusType.values.firstWhere(
        (element) => element.value == typeValue,
        orElse: () {
          throw ArgumentError(
            'Unknown RampWidgetStatusEvents value: $typeValue',
          );
        },
      );
    } catch (e) {
      // Handle various errors
      if (e is FormatException) {
        throw FormatException('Invalid JSON format: ${e.message}');
      } else if (e is ArgumentError) {
        rethrow; // Keep existing ArgumentError
      } else {
        throw ArgumentError('Error parsing RampWidgetStatusEvents: $e');
      }
    }
  }

  /// Checks if a string is a valid Ramp widget event
  static bool isValidEvent(String eventType) {
    return PaymentStatusType.values.any(
      (element) => element.value == eventType,
    );
  }
}
