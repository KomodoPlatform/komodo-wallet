part of 'fiat_form_bloc.dart';

enum FiatFormStatus { initial, loading, success, failure }

final class FiatFormState extends Equatable with FormzMixin {
  const FiatFormState({
    required this.selectedFiat,
    required this.selectedCoin,
    required this.fiatAmount,
    required this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.accountReference,
    required this.coinReceiveAddress,
    required this.checkoutUrl,
    required this.orderId,
    required this.fiatList,
    required this.coinList,
    this.status = FiatFormStatus.initial,
    this.fiatOrderStatus = FiatOrderStatus.pending,
    this.fiatMode = FiatMode.onramp,
  });

  const FiatFormState.initial()
      : selectedFiat = const CurrencyInput.dirty(
          FiatCurrency('USD', 'United States Dollar'),
        ),
        selectedCoin = const CurrencyInput.dirty(
          CryptoCurrency('BTC', 'Bitcoin', CoinType.utxo),
        ),
        fiatAmount = const FiatAmountInput.pure(),
        selectedPaymentMethod = const FiatPaymentMethod.none(),
        accountReference = '',
        coinReceiveAddress = '',
        checkoutUrl = '',
        orderId = '',
        status = FiatFormStatus.initial,
        paymentMethods = const [],
        fiatList = const [],
        coinList = const [],
        fiatOrderStatus = FiatOrderStatus.pending,
        fiatMode = FiatMode.onramp;

  /// The selected fiat currency to use to purchase [selectedCoin].
  final CurrencyInput selectedFiat;

  /// The selected crypto currency to purchase.
  final CurrencyInput selectedCoin;

  /// The amount of [selectedFiat] to use to purchase [selectedCoin].
  final FiatAmountInput fiatAmount;

  /// The selected payment method to use to purchase [selectedCoin].
  final FiatPaymentMethod selectedPaymentMethod;

  /// The account reference to use to purchase [selectedCoin].
  final String accountReference;

  /// The crypto receive address to use to purchase [selectedCoin].
  final String coinReceiveAddress;

  /// The callback url to return to once checkout is completed.
  final String checkoutUrl;

  /// The order id for the fiat purchase (Only supported by Banxa).
  final String orderId;

  /// The current status of the form (loading, success, failure).
  final FiatFormStatus status;

  /// The list of payment methods available for the [selectedFiat],
  /// [selectedCoin], and [fiatAmount].
  final Iterable<FiatPaymentMethod> paymentMethods;

  /// The list of fiat currencies that can be used to purchase [selectedCoin].
  final Iterable<ICurrency> fiatList;

  /// The list of crypto currencies that can be purchased.
  final Iterable<ICurrency> coinList;

  /// The current status of the fiat order.
  final FiatOrderStatus fiatOrderStatus;

  /// The current mode of the fiat form (onramp, offramp). This is currently
  /// used to determine the tab to show. The implementation will likely change
  /// once the order history tab is implemented
  final FiatMode fiatMode;

  /// Gets the transaction limit from the selected payment method
  FiatTransactionLimit? get transactionLimit =>
      selectedPaymentMethod.transactionLimits.firstOrNull;

  /// The minimum fiat amount that is allowed for the selected payment method
  double? get minFiatAmount => transactionLimit?.min;

  /// The maximum fiat amount that is allowed for the selected payment method
  double? get maxFiatAmount => transactionLimit?.max;
  bool get isLoadingCurrencies => fiatList.length < 2 || coinList.length < 2;
  bool get isLoading => isLoadingCurrencies || status == FiatFormStatus.loading;
  bool get canSubmit =>
      !isLoading &&
      accountReference.isNotEmpty &&
      status != FiatFormStatus.failure &&
      !fiatOrderStatus.isSubmitting &&
      isValid;

  FiatFormState copyWith({
    CurrencyInput? selectedFiat,
    CurrencyInput? selectedCoin,
    FiatAmountInput? fiatAmount,
    FiatPaymentMethod? selectedPaymentMethod,
    String? accountReference,
    String? coinReceiveAddress,
    String? checkoutUrl,
    String? orderId,
    FiatFormStatus? status,
    Iterable<FiatPaymentMethod>? paymentMethods,
    Iterable<ICurrency>? fiatList,
    Iterable<ICurrency>? coinList,
    FiatOrderStatus? fiatOrderStatus,
    FiatMode? fiatMode,
  }) {
    return FiatFormState(
      selectedFiat: selectedFiat ?? this.selectedFiat,
      selectedCoin: selectedCoin ?? this.selectedCoin,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      accountReference: accountReference ?? this.accountReference,
      coinReceiveAddress: coinReceiveAddress ?? this.coinReceiveAddress,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      orderId: orderId ?? this.orderId,
      fiatAmount: fiatAmount ?? this.fiatAmount,
      status: status ?? this.status,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      fiatList: fiatList ?? this.fiatList,
      coinList: coinList ?? this.coinList,
      fiatOrderStatus: fiatOrderStatus ?? this.fiatOrderStatus,
      fiatMode: fiatMode ?? this.fiatMode,
    );
  }

  @override
  List<FormzInput<dynamic, dynamic>> get inputs => [
        selectedFiat,
        selectedCoin,
        fiatAmount,
      ];

  @override
  List<Object?> get props => [
        selectedFiat,
        selectedCoin,
        selectedPaymentMethod,
        accountReference,
        coinReceiveAddress,
        checkoutUrl,
        orderId,
        fiatAmount,
        status,
        paymentMethods,
        fiatList,
        coinList,
        fiatOrderStatus,
        fiatMode,
      ];
}
