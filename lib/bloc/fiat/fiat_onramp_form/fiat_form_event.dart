part of 'fiat_form_bloc.dart';

sealed class FiatFormEvent extends Equatable {
  const FiatFormEvent();

  @override
  List<Object> get props => [];
}

final class FiatFormStarted extends FiatFormEvent {
  const FiatFormStarted();
}

final class FiatFormOnRampPaymentStatusMessageReceived extends FiatFormEvent {
  const FiatFormOnRampPaymentStatusMessageReceived(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

final class FiatFormFiatSelected extends FiatFormEvent {
  const FiatFormFiatSelected(this.selectedFiat);

  final FiatCurrency selectedFiat;

  @override
  List<Object> get props => [selectedFiat];
}

final class FiatFormCoinSelected extends FiatFormEvent {
  const FiatFormCoinSelected(this.selectedCoin);

  final CryptoCurrency selectedCoin;

  @override
  List<Object> get props => [selectedCoin];
}

final class FiatFormAmountUpdated extends FiatFormEvent {
  const FiatFormAmountUpdated(this.fiatAmount);

  final String fiatAmount;

  @override
  List<Object> get props => [fiatAmount];
}

final class FiatFormPaymentMethodSelected extends FiatFormEvent {
  const FiatFormPaymentMethodSelected(this.paymentMethod);

  final FiatPaymentMethod paymentMethod;

  @override
  List<Object> get props => [paymentMethod];
}

final class FiatFormSubmitted extends FiatFormEvent {}

final class FiatFormModeUpdated extends FiatFormEvent {
  const FiatFormModeUpdated(this.mode);

  FiatFormModeUpdated.fromTabIndex(int tabIndex)
      : mode = FiatMode.fromTabIndex(tabIndex);

  final FiatMode mode;

  @override
  List<Object> get props => [mode];
}

final class FiatFormPaymentStatusCleared extends FiatFormEvent {
  const FiatFormPaymentStatusCleared();
}

final class FiatFormWalletAuthenticated extends FiatFormEvent {
  const FiatFormWalletAuthenticated();
}

final class FiatFormAccountCleared extends FiatFormEvent {
  const FiatFormAccountCleared();
}

final class FiatFormRefreshed extends FiatFormEvent {
  const FiatFormRefreshed({
    this.forceRefresh = false,
  });

  final bool forceRefresh;

  @override
  List<Object> get props => [forceRefresh];
}

final class FiatFormCurrenciesFetched extends FiatFormEvent {
  const FiatFormCurrenciesFetched();
}

final class FiatFormOrderStatusWatchStarted extends FiatFormEvent {
  const FiatFormOrderStatusWatchStarted();
}

final class FiatFormCoinAddressSelected extends FiatFormEvent {
  const FiatFormCoinAddressSelected(this.address);

  final PubkeyInfo address;

  @override
  List<Object> get props => [address];
}
