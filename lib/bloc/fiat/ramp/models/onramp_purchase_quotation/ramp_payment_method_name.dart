enum RampPaymentMethodName {
  manualBankTransfer('MANUAL_BANK_TRANSFER'),
  autoBankTransfer('AUTO_BANK_TRANSFER'),
  cardPayment('CARD_PAYMENT'),
  applePay('APPLE_PAY'),
  googlePay('GOOGLE_PAY'),
  pix('PIX'),
  openBanking('OPEN_BANKING');

  const RampPaymentMethodName(this.value);
  final String value;

  static RampPaymentMethodName? fromString(String value) {
    return RampPaymentMethodName.values.firstWhere(
      (element) => element.value == value,
      orElse: () => throw ArgumentError('Unknown payment method: $value'),
    );
  }
}
