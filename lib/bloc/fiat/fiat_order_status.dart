// TODO: Differentiate between different error and in-progress statuses
import 'package:logging/logging.dart';

enum FiatOrderStatus {
  /// Initial status: User has not yet started the payment process
  initial,

  /// User has started the process, and the payment method has been opened.
  /// E.g. Ramp or Banxa websites have been opened
  submitted,

  /// Payment is awaiting user action (e.g., user needs to complete payment)
  pendingPayment,

  /// Payment has been submitted with the provider, and is being processed
  inProgress,

  /// Payment has been completed successfully
  success,

  /// Payment has been cancelled, declined, expired or refunded
  failed,

  /// The user closed the payment window using the provider close button
  /// or "return to Komodo Wallet" button
  windowCloseRequested;

  bool get isTerminal =>
      this == FiatOrderStatus.success || this == FiatOrderStatus.failed;
  bool get isSubmitting =>
      this == FiatOrderStatus.inProgress ||
      this == FiatOrderStatus.submitted ||
      this == FiatOrderStatus.pendingPayment;
  bool get isFailed => this == FiatOrderStatus.failed;
  bool get isSuccess => this == FiatOrderStatus.success;

  /// Parses the fiat order status form string
  /// Throws [Exception] if the string is not a valid status
  static FiatOrderStatus fromString(String status) {
    // The case statements are references to Banxa's order statuses. See the
    // docs link here for more info: https://docs.banxa.com/docs/order-status
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'complete':
        return FiatOrderStatus.success;

      case 'cancelled':
      case 'declined':
      case 'expired':
      case 'refunded':
        return FiatOrderStatus.failed;

      case 'extraverification':
      case 'pendingpayment':
      case 'waitingpayment':
        return FiatOrderStatus.pendingPayment;

      case 'paymentreceived':
      case 'inprogress':
      case 'cointransferred':
      case 'cryptotransferred':
        return FiatOrderStatus.inProgress;

      default:
        // Default to in progress if the status is not recognized
        // to avoid alarming users with "Payment failed" popup messages
        // unless we are sure that the payment has failed.
        // Ideally, this section should not be reached.
        Logger('FiatOrderStatus')
            .warning('Unknown status: $status, defaulting to in progress');
        return FiatOrderStatus.inProgress;
    }
  }
}
