part of 'bitrefill_bloc.dart';

sealed class BitrefillEvent extends Equatable {
  const BitrefillEvent();

  @override
  List<Object> get props => [];
}

/// Request to load the bitrefill state with the url and supported coins
/// from the bitrefill provider.
final class BitrefillLoadRequested extends BitrefillEvent {
  const BitrefillLoadRequested({this.coin, this.refundAddress});

  final Coin? coin;
  final String? refundAddress;

  @override
  List<Object> get props => [coin?.abbr ?? '', refundAddress ?? ''];
}

/// Request to open the Bitrefill widget to make a purchase
final class BitrefillLaunchRequested extends BitrefillEvent {
  const BitrefillLaunchRequested();

  @override
  List<Object> get props => [];
}

/// Event that is fired when the Bitrefill payment intent is received
final class BitrefillPaymentIntentReceived extends BitrefillEvent {
  const BitrefillPaymentIntentReceived(this.paymentIntentRecieved);

  final BitrefillPaymentIntentEvent paymentIntentRecieved;

  @override
  List<Object> get props => [paymentIntentRecieved];
}

/// Payment was completed successfully in the Withdrawal page
final class BitrefillPaymentCompleted extends BitrefillEvent {
  const BitrefillPaymentCompleted();

  @override
  List<Object> get props => [];
}
