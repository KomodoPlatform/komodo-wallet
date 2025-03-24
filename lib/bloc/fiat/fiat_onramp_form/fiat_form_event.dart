part of 'fiat_form_bloc.dart';

/// Base class for all events related to the Fiat Form.
sealed class FiatFormEvent extends Equatable {
  const FiatFormEvent();

  @override
  List<Object> get props => [];
}

/// Event emitted when the Fiat Form is initially started.
final class FiatFormStarted extends FiatFormEvent {
  const FiatFormStarted();
}

/// Event emitted when a payment status message is received from the on-ramp provider.
final class FiatFormOnRampPaymentStatusMessageReceived extends FiatFormEvent {
  const FiatFormOnRampPaymentStatusMessageReceived(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

/// Event emitted when a fiat currency is selected in the form.
final class FiatFormFiatSelected extends FiatFormEvent {
  const FiatFormFiatSelected(this.selectedFiat);

  final FiatCurrency selectedFiat;

  @override
  List<Object> get props => [selectedFiat];
}

/// Event emitted when a cryptocurrency is selected in the form.
final class FiatFormCoinSelected extends FiatFormEvent {
  const FiatFormCoinSelected(this.selectedCoin);

  final CryptoCurrency selectedCoin;

  @override
  List<Object> get props => [selectedCoin];
}

/// Event emitted when the fiat amount to be used for purchase is updated.
final class FiatFormAmountUpdated extends FiatFormEvent {
  const FiatFormAmountUpdated(this.fiatAmount);

  final String fiatAmount;

  @override
  List<Object> get props => [fiatAmount];
}

/// Event emitted when a payment method is selected.
final class FiatFormPaymentMethodSelected extends FiatFormEvent {
  const FiatFormPaymentMethodSelected(this.paymentMethod);

  final FiatPaymentMethod paymentMethod;

  @override
  List<Object> get props => [paymentMethod];
}

/// Event emitted when the form is submitted to initiate a purchase.
final class FiatFormSubmitted extends FiatFormEvent {
  const FiatFormSubmitted();
}

/// Event emitted when the form mode (on-ramp/off-ramp) is updated.
final class FiatFormModeUpdated extends FiatFormEvent {
  const FiatFormModeUpdated(this.mode);

  /// Constructor that creates a mode update event from a tab index.
  FiatFormModeUpdated.fromTabIndex(int tabIndex)
      : mode = FiatMode.fromTabIndex(tabIndex);

  final FiatMode mode;

  @override
  List<Object> get props => [mode];
}

/// Event emitted to clear the payment status.
final class FiatFormPaymentStatusCleared extends FiatFormEvent {
  const FiatFormPaymentStatusCleared();
}

/// Event emitted when the wallet is authenticated for a fiat transaction.
final class FiatFormWalletAuthenticated extends FiatFormEvent {
  const FiatFormWalletAuthenticated();
}

/// Event emitted to clear the current account data.
final class FiatFormAccountCleared extends FiatFormEvent {
  const FiatFormAccountCleared();
}

/// Event emitted to refresh the form data.
final class FiatFormRefreshed extends FiatFormEvent {
  const FiatFormRefreshed({
    this.forceRefresh = false,
  });

  /// Whether to force a refresh of data even if cache exists.
  final bool forceRefresh;

  @override
  List<Object> get props => [forceRefresh];
}

/// Event emitted to fetch available fiat and crypto currencies.
final class FiatFormCurrenciesFetched extends FiatFormEvent {
  const FiatFormCurrenciesFetched();
}

/// Event emitted to start watching the status of a fiat order.
final class FiatFormOrderStatusWatchStarted extends FiatFormEvent {
  const FiatFormOrderStatusWatchStarted();
}

/// Event emitted when a cryptocurrency address is selected for receiving funds.
final class FiatFormCoinAddressSelected extends FiatFormEvent {
  const FiatFormCoinAddressSelected(this.address);

  final PubkeyInfo address;

  @override
  List<Object> get props => [address];
}
