part of 'fiat_form_bloc.dart';

enum FiatFormStatus { initial, loading, success, failure }

final class FiatFormState extends Equatable with FormzMixin {
  const FiatFormState({
    required this.selectedFiat,
    required this.selectedAsset,
    required this.fiatAmount,
    required this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.checkoutUrl,
    required this.orderId,
    required this.fiatList,
    required this.coinList,
    this.status = FiatFormStatus.initial,
    this.fiatOrderStatus = FiatOrderStatus.pending,
    this.fiatMode = FiatMode.onramp,
    this.selectedAssetAddress,
    this.selectedCoinPubkeys,
  });

  const FiatFormState.initial()
      : selectedFiat = const CurrencyInput.dirty(
          FiatCurrency('USD', 'United States Dollar'),
        ),
        selectedAsset = const CurrencyInput.dirty(
          CryptoCurrency('BTC', 'Bitcoin', CoinType.utxo),
        ),
        fiatAmount = const FiatAmountInput.pure(),
        selectedAssetAddress = null,
        selectedPaymentMethod = const FiatPaymentMethod.none(),
        checkoutUrl = '',
        orderId = '',
        status = FiatFormStatus.initial,
        paymentMethods = const [],
        fiatList = const [],
        coinList = const [],
        fiatOrderStatus = FiatOrderStatus.pending,
        fiatMode = FiatMode.onramp,
        selectedCoinPubkeys = null;

  /// The selected fiat currency to use to purchase [selectedAsset].
  final CurrencyInput selectedFiat;

  /// The selected crypto currency to purchase.
  final CurrencyInput selectedAsset;

  /// The amount of [selectedFiat] to use to purchase [selectedAsset].
  final FiatAmountInput fiatAmount;

  /// The selected payment method to use to purchase [selectedAsset].
  final FiatPaymentMethod selectedPaymentMethod;

  /// The crypto receive address to use to purchase [selectedAsset].
  final PubkeyInfo? selectedAssetAddress;

  /// The public keys associated with the selected crypto currency.
  final AssetPubkeys? selectedCoinPubkeys;

  /// The callback url to return to once checkout is completed.
  final String checkoutUrl;

  /// The order id for the fiat purchase (Only supported by Banxa).
  final String orderId;

  /// The current status of the form (loading, success, failure).
  final FiatFormStatus status;

  /// The list of payment methods available for the [selectedFiat],
  /// [selectedAsset], and [fiatAmount].
  final Iterable<FiatPaymentMethod> paymentMethods;

  /// The list of fiat currencies that can be used to purchase [selectedAsset].
  final Iterable<FiatCurrency> fiatList;

  /// The list of crypto currencies that can be purchased.
  final Iterable<CryptoCurrency> coinList;

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
      selectedAssetAddress != null &&
      status != FiatFormStatus.failure &&
      !fiatOrderStatus.isSubmitting &&
      isValid;

  FiatFormState copyWith({
    CurrencyInput? selectedFiat,
    CurrencyInput? selectedAsset,
    FiatAmountInput? fiatAmount,
    FiatPaymentMethod? selectedPaymentMethod,
    PubkeyInfo? selectedAssetAddress,
    String? checkoutUrl,
    String? orderId,
    FiatFormStatus? status,
    Iterable<FiatPaymentMethod>? paymentMethods,
    Iterable<FiatCurrency>? fiatList,
    Iterable<CryptoCurrency>? coinList,
    FiatOrderStatus? fiatOrderStatus,
    FiatMode? fiatMode,
    AssetPubkeys? selectedCoinPubkeys,
  }) {
    return FiatFormState(
      selectedFiat: selectedFiat ?? this.selectedFiat,
      selectedAsset: selectedAsset ?? this.selectedAsset,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      selectedAssetAddress: selectedAssetAddress ?? this.selectedAssetAddress,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      orderId: orderId ?? this.orderId,
      fiatAmount: fiatAmount ?? this.fiatAmount,
      status: status ?? this.status,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      fiatList: fiatList ?? this.fiatList,
      coinList: coinList ?? this.coinList,
      fiatOrderStatus: fiatOrderStatus ?? this.fiatOrderStatus,
      fiatMode: fiatMode ?? this.fiatMode,
      selectedCoinPubkeys: selectedCoinPubkeys ?? this.selectedCoinPubkeys,
    );
  }

  @override
  List<FormzInput<dynamic, dynamic>> get inputs => [
        selectedFiat,
        selectedAsset,
        fiatAmount,
      ];

  @override
  List<Object?> get props => [
        selectedFiat,
        selectedAsset,
        selectedPaymentMethod,
        selectedAssetAddress,
        checkoutUrl,
        orderId,
        fiatAmount,
        status,
        paymentMethods,
        fiatList,
        coinList,
        fiatOrderStatus,
        fiatMode,
        selectedCoinPubkeys,
      ];
}
