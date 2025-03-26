import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/fiat/base_fiat_provider.dart';
import 'package:web_dex/bloc/fiat/fiat_order_status.dart';
import 'package:web_dex/bloc/fiat/fiat_repository.dart';
import 'package:web_dex/bloc/fiat/models/models.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/forms/fiat/currency_input.dart';
import 'package:web_dex/model/forms/fiat/fiat_amount_input.dart';
import 'package:web_dex/shared/utils/extensions/string_extensions.dart';

part 'fiat_form_event.dart';
part 'fiat_form_state.dart';

class FiatFormBloc extends Bloc<FiatFormEvent, FiatFormState> {
  FiatFormBloc({
    required FiatRepository repository,
    required KomodoDefiSdk sdk,
  })  : _fiatRepository = repository,
        _sdk = sdk,
        super(FiatFormState.initial()) {
    on<FiatFormStarted>(_onStarted);

    // All user input fields are debounced using the debounce stream transformer
    on<FiatFormFiatSelected>(_onFiatSelected);
    on<FiatFormCoinSelected>(_onCoinSelected);
    on<FiatFormAmountUpdated>(_onAmountUpdated);
    on<FiatFormPaymentMethodSelected>(_onSelectPaymentMethod);
    on<FiatFormSubmitted>(_onSubmitForm);
    on<FiatFormOnRampPaymentStatusMessageReceived>(_onPaymentStatusMessage);
    on<FiatFormModeUpdated>(_onModeUpdated);
    on<FiatFormWalletAuthenticated>(_onWalletAuthenticated);
    on<FiatFormAccountCleared>(_onClearAccountInformation);
    on<FiatFormCoinAddressSelected>(_onCoinAddressSelected);

    // debounce used here instead of restartable, since multiple user actions
    // can trigger this event, and restartable results in hitching
    on<FiatFormRefreshed>(_onRefreshForm, transformer: restartable());
    on<FiatFormCurrenciesFetched>(
      _onLoadCurrencyLists,
      transformer: restartable(),
    );
    on<FiatFormOrderStatusWatchStarted>(
      _onWatchOrderStatus,
      transformer: restartable(),
    );
  }

  final FiatRepository _fiatRepository;
  final KomodoDefiSdk _sdk;
  final _log = Logger('FiatFormBloc');

  void _onStarted(
    FiatFormStarted event,
    Emitter<FiatFormState> emit,
  ) {
    add(const FiatFormCurrenciesFetched());
  }

  Future<void> _onFiatSelected(
    FiatFormFiatSelected event,
    Emitter<FiatFormState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedFiat: CurrencyInput.dirty(event.selectedFiat),
      ),
    );
  }

  Future<void> _onCoinSelected(
    FiatFormCoinSelected event,
    Emitter<FiatFormState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedAsset: CurrencyInput.dirty(event.selectedCoin),
      ),
    );

    try {
      final asset = event.selectedCoin.toAsset(_sdk);
      final assetPubkeys = await _sdk.pubkeys.getPubkeys(asset);
      final address = assetPubkeys.keys.firstOrNull;

      emit(
        state.copyWith(
          selectedAssetAddress: address,
          selectedCoinPubkeys: assetPubkeys,
        ),
      );
    } catch (e, s) {
      _log.shout('Error getting pubkeys for selected coin', e, s);
      emit(state.copyWith(selectedAssetAddress: null));
    }
  }

  Future<void> _onAmountUpdated(
    FiatFormAmountUpdated event,
    Emitter<FiatFormState> emit,
  ) async {
    emit(
      state.copyWith(fiatAmount: _getAmountInputWithBounds(event.fiatAmount)),
    );
  }

  void _onSelectPaymentMethod(
    FiatFormPaymentMethodSelected event,
    Emitter<FiatFormState> emit,
  ) {
    emit(
      state.copyWith(
        selectedPaymentMethod: event.paymentMethod,
        fiatAmount: _getAmountInputWithBounds(
          state.fiatAmount.value,
          selectedPaymentMethod: event.paymentMethod,
        ),
        fiatOrderStatus: FiatOrderStatus.pending,
        status: FiatFormStatus.initial,
      ),
    );
  }

  Future<void> _onSubmitForm(
    FiatFormSubmitted event,
    Emitter<FiatFormState> emit,
  ) async {
    final formValidationError = getFormIssue();
    if (formValidationError != null || !state.isValid) {
      _log.warning('Form validation failed. Validation: ${state.isValid}');
      return;
    }

    if (state.checkoutUrl.isNotEmpty) {
      emit(state.copyWith(checkoutUrl: ''));
    }

    try {
      final newOrder = await _fiatRepository.buyCoin(
        state.selectedAssetAddress!.address,
        state.selectedFiat.value!.symbol,
        state.selectedAsset.value!,
        state.selectedAssetAddress!.address,
        state.selectedPaymentMethod,
        state.fiatAmount.value,
        BaseFiatProvider.successUrl(state.selectedAssetAddress!.address),
      );

      if (!newOrder.error.isNone) {
        _log.warning('Order creation returned an error: ${newOrder.error}');
        return emit(_parseOrderError(newOrder.error));
      }

      final checkoutUrl = newOrder.checkoutUrl as String? ?? '';
      if (checkoutUrl.isEmpty) {
        _log.severe('Invalid checkout URL received.');
        return emit(
          state.copyWith(
            fiatOrderStatus: FiatOrderStatus.failed,
          ),
        );
      }

      emit(
        state.copyWith(
          checkoutUrl: checkoutUrl,
          orderId: newOrder.id,
          status: FiatFormStatus.success,
          fiatOrderStatus: FiatOrderStatus.submitted,
        ),
      );
    } catch (e, s) {
      _log.shout('Error submitting fiat form', e, s);
      emit(
        state.copyWith(
          status: FiatFormStatus.failure,
          checkoutUrl: '',
        ),
      );
    }
  }

  Future<void> _onRefreshForm(
    FiatFormRefreshed event,
    Emitter<FiatFormState> emit,
  ) async {
    final refreshStateStream = _refreshFormState();
    await emit.forEach(refreshStateStream, onData: (newState) => newState);
  }

  Future<void> _onWalletAuthenticated(
    FiatFormWalletAuthenticated event,
    Emitter<FiatFormState> emit,
  ) async {
    try {
      final asset =
          _sdk.getSdkAsset(state.selectedAsset.value?.symbol ?? 'BTC-segwit');
      final assetPubkeys = await _sdk.pubkeys.getPubkeys(asset);

      emit(
        state.copyWith(
          selectedAssetAddress: assetPubkeys.keys.firstOrNull,
          selectedCoinPubkeys: assetPubkeys,
        ),
      );
    } catch (e, s) {
      _log.shout('Error getting pubkeys after wallet authentication', e, s);
      emit(state.copyWith(selectedAssetAddress: null));
    }
  }

  void _onClearAccountInformation(
    FiatFormAccountCleared event,
    Emitter<FiatFormState> emit,
  ) {
    emit(FiatFormState.initial());
  }

  Future<FiatFormState> _updateAssetPubkeys() async {
    try {
      final asset = _sdk.getSdkAsset(state.selectedAsset.value!.symbol);
      final pubkeys = await _sdk.pubkeys.getPubkeys(asset);
      final address = pubkeys.keys.firstOrNull;

      return state.copyWith(
        selectedAssetAddress: address,
        selectedCoinPubkeys: pubkeys,
      );
    } catch (e, s) {
      _log.shout('Error updating asset pubkeys', e, s);
      return state.copyWith(selectedAssetAddress: null);
    }
  }

  void _onPaymentStatusMessage(
    FiatFormOnRampPaymentStatusMessageReceived event,
    Emitter<FiatFormState> emit,
  ) {
    if (!event.message.isJson()) {
      _log.severe('Invalid json console message received');
      return;
    }

    try {
      // Escaped strings are decoded to unescaped strings instead of json
      // objects :(
      String message = event.message;
      if (jsonDecode(event.message) is String) {
        message = jsonDecode(message) as String;
      }
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (_isCheckoutStatusMessage(data)) {
        final status = data['status'] as String? ?? 'declined';
        emit(
          state.copyWith(
            fiatOrderStatus: FiatOrderStatus.fromString(status),
          ),
        );
      }
    } catch (e, s) {
      _log.shout('Error parsing payment status message', e, s);
    }
  }

  void _onCoinAddressSelected(
    FiatFormCoinAddressSelected event,
    Emitter<FiatFormState> emit,
  ) {
    emit(
      state.copyWith(
        selectedAssetAddress: event.address,
      ),
    );
  }

  void _onModeUpdated(
    FiatFormModeUpdated event,
    Emitter<FiatFormState> emit,
  ) {
    emit(state.copyWith(fiatMode: event.mode));
  }

  Future<void> _onLoadCurrencyLists(
    FiatFormCurrenciesFetched event,
    Emitter<FiatFormState> emit,
  ) async {
    try {
      final fiatList = await _fiatRepository.getFiatList();
      final coinList = await _fiatRepository.getCoinList();
      emit(state.copyWith(fiatList: fiatList, coinList: coinList));
    } catch (e, s) {
      _log.shout('Error loading currency list', e, s);
      emit(state.copyWith(
        fiatList: [],
        coinList: [],
        status: FiatFormStatus.failure,
      ));
    }
  }

  Future<void> _onWatchOrderStatus(
    FiatFormOrderStatusWatchStarted event,
    Emitter<FiatFormState> emit,
  ) async {
    // banxa implementation monitors status using their API, so watch the order
    // status via the existing repository methods
    if (state.selectedPaymentMethod.providerId != 'Banxa') {
      return;
    }

    try {
      final orderStatusStream = _fiatRepository.watchOrderStatus(
        state.selectedPaymentMethod,
        state.orderId,
      );

      return await emit.forEach(
        orderStatusStream,
        onData: (data) => state.copyWith(fiatOrderStatus: data),
        onError: (error, stackTrace) {
          _log.shout('Error watching order status', error, stackTrace);
          return state.copyWith(fiatOrderStatus: FiatOrderStatus.failed);
        },
      );
    } catch (e, s) {
      _log.shout('Error setting up order status watch', e, s);
      emit(state.copyWith(fiatOrderStatus: FiatOrderStatus.failed));
    }
  }

  bool _isCheckoutStatusMessage(Map<String, dynamic> data) {
    return data.containsKey('type') && (data['type'] == 'PAYMENT-STATUS');
  }

  FiatFormState _parseOrderError(FiatBuyOrderError error) {
    // TODO? banxa can return an error indicating that a higher fiat amount is
    // required, which could be indicated to the user. The only issue is that
    // it is text-based and does not match the value returned in their payment
    // method list
    return state.copyWith(
      checkoutUrl: '',
      status: FiatFormStatus.failure,
      fiatOrderStatus: FiatOrderStatus.failed,
    );
  }

  String? getFormIssue() {
    // TODO: ? show on the UI and localise? These are currently used as more of
    // a boolean "is there an error?" rather than "what is the error?"
    if (state.paymentMethods.isEmpty) {
      return 'No payment method for this pair';
    }
    if (state.selectedAssetAddress == null) {
      return 'No wallet, or coin/network might not be supported';
    }

    return null;
  }

  FiatAmountInput _getAmountInputWithBounds(
    String amount, {
    FiatPaymentMethod? selectedPaymentMethod,
  }) {
    Decimal? minAmount;
    Decimal? maxAmount;
    final paymentMethod = selectedPaymentMethod ?? state.selectedPaymentMethod;
    final firstLimit = paymentMethod.transactionLimits.firstOrNull;
    if (firstLimit != null) {
      minAmount = Decimal.tryParse(firstLimit.min.toString());
      maxAmount = Decimal.tryParse(firstLimit.max.toString());
    }

    return FiatAmountInput.dirty(
      amount,
      minValue: minAmount,
      maxValue: maxAmount,
    );
  }

  Stream<FiatFormState> _refreshFormState() async* {
    // Step 1: Handle initial state based on fiat amount
    yield* _handleInitialState();

    // Step 2: Update amount bounds
    yield state.copyWith(
        fiatAmount: _getAmountInputWithBounds(state.fiatAmount.value));

    // Step 3: Update asset information and payment methods
    try {
      yield await _updateAssetPubkeys();
      yield* _fetchAndUpdatePaymentMethods();
    } catch (error, stacktrace) {
      _log.shout('Error refreshing form data', error, stacktrace);
      yield state.copyWith(
        paymentMethods: [],
        status: FiatFormStatus.failure,
      );
    }
  }

  Stream<FiatFormState> _handleInitialState() async* {
    if (_hasValidFiatAmount()) {
      yield state.copyWith(
        status: FiatFormStatus.loading,
        fiatOrderStatus: FiatOrderStatus.pending,
      );
    } else {
      yield _defaultPaymentMethods();
    }
  }

  Stream<FiatFormState> _fetchAndUpdatePaymentMethods() async* {
    final methodsStream = _fiatRepository.getPaymentMethodsList(
      state.selectedFiat.value!.symbol,
      state.selectedAsset.value!,
      _getSourceAmount(),
    );

    try {
      await for (final methods in methodsStream) {
        yield _updatePaymentMethods(methods, forceUpdate: true);
      }
    } catch (e, s) {
      _log.shout('Error fetching payment methods', e, s);
      yield state.copyWith(
        paymentMethods: [],
        status: FiatFormStatus.failure,
      );
    }
  }

  String _getSourceAmount() {
    return _hasValidFiatAmount() ? state.fiatAmount.value : '10000';
  }

  bool _hasValidFiatAmount() {
    return state.fiatAmount.valueAsDecimal != null &&
        state.fiatAmount.valueAsDecimal != Decimal.zero;
  }

  FiatFormState _updatePaymentMethods(
    List<FiatPaymentMethod> methods, {
    bool forceUpdate = false,
  }) {
    try {
      final shouldUpdate = forceUpdate || state.selectedPaymentMethod.isNone;
      if (shouldUpdate && methods.isNotEmpty) {
        final method = state.selectedPaymentMethod.isNone
            ? methods.first
            : methods.firstWhere(
                (method) => method.id == state.selectedPaymentMethod.id,
                orElse: () => methods.first,
              );

        return state.copyWith(
          paymentMethods: methods,
          selectedPaymentMethod: method,
          status: FiatFormStatus.success,
          fiatAmount: _getAmountInputWithBounds(
            state.fiatAmount.value,
            selectedPaymentMethod: method,
          ),
        );
      }

      return state.copyWith(status: FiatFormStatus.success);
    } catch (e, s) {
      _log.shout('Error updating payment methods', e, s);
      return state.copyWith(paymentMethods: []);
    }
  }

  FiatFormState _defaultPaymentMethods() {
    return state.copyWith(
      paymentMethods: defaultFiatPaymentMethods,
      selectedPaymentMethod: defaultFiatPaymentMethods.first,
      status: FiatFormStatus.initial,
      fiatOrderStatus: FiatOrderStatus.pending,
    );
  }
}
