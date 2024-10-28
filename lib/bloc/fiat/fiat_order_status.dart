// TODO: Differentiate between different error and in-progress statuses
enum FiatOrderStatus {
  /// User has not yet started the payment process
  pending,

  /// User has started the process, and a payment request has been submitted
  submitted,

  /// Payment has been submitted and is being processed
  inProgress,

  /// Payment has been completed successfully
  success,

  /// Payment has been cancelled, declined, expired or refunded
  failed;

  bool get isTerminal =>
      this == FiatOrderStatus.success || this == FiatOrderStatus.failed;
  bool get isSubmitting =>
      this == FiatOrderStatus.inProgress || this == FiatOrderStatus.submitted;
  bool get isFailed => this == FiatOrderStatus.failed;
  bool get isSuccess => this == FiatOrderStatus.success;

  /// Parses the fiat order status form string
  /// Throws [Exception] if the string is not a valid status
  static FiatOrderStatus fromString(String status) {
    // The case statements are references to Banxa's order statuses. See the
    // docs link here for more info: https://docs.banxa.com/docs/order-status
    switch (status) {
      case 'complete':
        return FiatOrderStatus.success;

      case 'cancelled':
      case 'declined':
      case 'expired':
      case 'refunded':
        return FiatOrderStatus.failed;

      case 'extraVerification':
      case 'pendingPayment':
      case 'waitingPayment':
        return FiatOrderStatus.pending;

      case 'paymentReceived':
      case 'inProgress':
      case 'coinTransferred':
        return FiatOrderStatus.inProgress;

      default:
        throw Exception('Unknown status: $status');
    }
  }
}
