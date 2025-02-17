part of 'fiat_form_bloc.dart';

sealed class FiatFormEvent extends Equatable {
  const FiatFormEvent();

  @override
  List<Object> get props => [];
}

final class FiatOnRampPaymentStatusMessageReceived extends FiatFormEvent {
  const FiatOnRampPaymentStatusMessageReceived(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

final class SelectedFiatCurrencyChanged extends FiatFormEvent {
  const SelectedFiatCurrencyChanged(this.selectedFiat);

  final ICurrency selectedFiat;

  @override
  List<Object> get props => [selectedFiat];
}

final class SelectedCoinChanged extends FiatFormEvent {
  const SelectedCoinChanged(this.selectedCoin);

  final ICurrency selectedCoin;

  @override
  List<Object> get props => [selectedCoin];
}

final class FiatAmountChanged extends FiatFormEvent {
  const FiatAmountChanged(this.fiatAmount);

  final String fiatAmount;

  @override
  List<Object> get props => [fiatAmount];
}

final class PaymentMethodSelected extends FiatFormEvent {
  const PaymentMethodSelected(this.paymentMethod);

  final FiatPaymentMethod paymentMethod;

  @override
  List<Object> get props => [paymentMethod];
}

final class FormSubmissionRequested extends FiatFormEvent {}

final class FiatModeChanged extends FiatFormEvent {
  const FiatModeChanged(this.mode);

  FiatModeChanged.fromTabIndex(int tabIndex)
      : mode = FiatMode.fromTabIndex(tabIndex);

  final FiatMode mode;

  @override
  List<Object> get props => [mode];
}

final class PaymentStatusClearRequested extends FiatFormEvent {
  const PaymentStatusClearRequested();
}

final class AccountInformationChanged extends FiatFormEvent {
  const AccountInformationChanged();
}

final class ClearAccountInformationRequested extends FiatFormEvent {
  const ClearAccountInformationRequested();
}

final class RefreshFormRequested extends FiatFormEvent {
  const RefreshFormRequested({
    this.forceRefresh = false,
  });

  final bool forceRefresh;

  @override
  List<Object> get props => [forceRefresh];
}

final class LoadCurrencyListsRequested extends FiatFormEvent {
  const LoadCurrencyListsRequested();
}

final class WatchOrderStatusRequested extends FiatFormEvent {
  const WatchOrderStatusRequested();
}
