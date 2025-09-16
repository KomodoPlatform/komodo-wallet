import 'package:equatable/equatable.dart';
import 'package:web_dex/bloc/bitrefill/models/bitrefill_event.dart';

/// The event that is dispatched when a Bitrefill payment intent is created (i.e. user clicks "Pay").
class BitrefillPaymentIntentEvent extends Equatable
    implements BitrefillWidgetEvent {
  const BitrefillPaymentIntentEvent({
    this.event,
    this.invoiceId,
    this.paymentUri,
    this.paymentMethod,
    this.paymentAmount,
    this.paymentCurrency,
    this.paymentAddress,
  });

  factory BitrefillPaymentIntentEvent.fromJson(Map<String, dynamic> json) {
    return BitrefillPaymentIntentEvent(
      event: json['event'] as String?,
      invoiceId: json['invoiceId'] as String?,
      paymentUri: json['paymentUri'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble(),
      paymentCurrency: json['paymentCurrency'] as String?,
      paymentAddress: json['paymentAddress'] as String?,
    );
  }

  /// The event type. E.g. `invoice_created`
  final String? event;

  /// The Bitrefill invoice ID. This is used to track the payment.
  final String? invoiceId;

  /// The payment URI containing the payment method, address and amount.
  /// E.g. `bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.1`
  final String? paymentUri;

  /// The payment method. E.g. `bitcoin`
  final String? paymentMethod;

  /// The payment amount. E.g. `0.1`
  final double? paymentAmount;

  /// The payment currency. E.g. `BTC`
  final String? paymentCurrency;

  /// The payment address. E.g. `1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa`
  final String? paymentAddress;

  Map<String, dynamic> toJson() => {
        'event': event,
        'invoiceId': invoiceId,
        'paymentUri': paymentUri,
        'paymentMethod': paymentMethod,
        'paymentAmount': paymentAmount,
        'paymentCurrency': paymentCurrency,
        'paymentAddress': paymentAddress,
      };

  @override
  List<Object?> get props {
    return [
      event,
      invoiceId,
      paymentUri,
      paymentMethod,
      paymentAmount,
      paymentCurrency,
      paymentAddress,
    ];
  }
}
