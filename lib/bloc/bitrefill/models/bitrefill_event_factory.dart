import 'package:komodo_wallet/bloc/bitrefill/models/bitrefill_event.dart';
import 'package:komodo_wallet/bloc/bitrefill/models/bitrefill_invoice_created_event.dart';
import 'package:komodo_wallet/bloc/bitrefill/models/bitrefill_payment_intent_event.dart';

/// A factory class that creates [BitrefillWidgetEvent] objects from JSON maps.
/// The event type is expected to be a string with the key 'event'.
class BitrefillEventFactory {
  /// Creates a [BitrefillWidgetEvent] from a JSON map using the event type
  /// specified in the map. The event type is expected to be a string with the
  /// key 'event'.
  static BitrefillWidgetEvent createEvent(Map<String, dynamic> json) {
    switch (json['event']) {
      case 'payment_intent':
        return BitrefillPaymentIntentEvent.fromJson(json);
      case 'invoice_created':
        return BitrefillInvoiceCreatedEvent.fromJson(json);
      default:
        throw Exception('Unknown event type: ${json['event']}');
    }
  }
}
