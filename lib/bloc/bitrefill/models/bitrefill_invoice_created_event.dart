import 'package:equatable/equatable.dart';
import 'package:web_dex/bloc/bitrefill/models/bitrefill_event.dart';

/// An event that is dispatched when a Bitrefill invoice is created.
/// This happens before a payment request is made (i.e. before the user clicks "Pay").
class BitrefillInvoiceCreatedEvent extends Equatable
    implements BitrefillWidgetEvent {
  const BitrefillInvoiceCreatedEvent({
    this.event,
    this.invoiceId,
    this.paymentUri,
    this.paymentMethod,
    this.paymentAmount,
    this.paymentCurrency,
    this.paymentAddress,
  });

  factory BitrefillInvoiceCreatedEvent.fromJson(Map<String, dynamic> json) {
    return BitrefillInvoiceCreatedEvent(
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

  Map<String, dynamic> toJson() => <String, dynamic>{
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
    return <Object?>[
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
