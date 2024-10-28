import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:web_dex/bloc/fiat/base_fiat_provider.dart';
import 'package:web_dex/bloc/fiat/fiat_order_status.dart';
import 'package:web_dex/bloc/fiat/fiat_repository.dart';
import 'package:web_dex/bloc/fiat/models/models.dart';
import 'package:web_dex/bloc/transformers.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/blocs/coins_bloc.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/forms/fiat/currency_input.dart';
import 'package:web_dex/model/forms/fiat/fiat_amount_input.dart';
import 'package:web_dex/shared/utils/extensions/string_extensions.dart';
import 'package:web_dex/shared/utils/utils.dart';

part 'fiat_form_event.dart';
part 'fiat_form_state.dart';

class FiatFormBloc extends Bloc<FiatFormEvent, FiatFormState> {
  FiatFormBloc({
    FiatRepository? repository,
    // TODO: update to respository reference once refactored
    CoinsBloc? coinsRepository,
  })  : _fiatRepository = repository ?? fiatRepository,
        _coinsRepository = coinsRepository ?? coinsBloc,
        super(const FiatFormState.initial()) {
    // all user input fields are debounced using the debounce stream transformer
    on<SelectedFiatCurrencyChanged>(
      _onChangeSelectedFiatCoin,
      transformer: debounce(500),
    );
    on<SelectedCoinChanged>(_onChangeSelectedCoin, transformer: debounce(500));
    on<FiatAmountChanged>(_onUpdateFiatAmount, transformer: debounce(500));
    on<PaymentMethodSelected>(_onSelectPaymentMethod);
    on<FormSubmissionRequested>(_onSubmitForm);
    on<FiatOnRampPaymentStatusMessageReceived>(_onPaymentStatusMessage);
    on<FiatModeChanged>(_onFiatModeChanged);
    on<AccountInformationChanged>(_onAccountInformationChanged);
    on<ClearAccountInformationRequested>(_onClearAccountInformation);
    // debounce used here instead of restartable, since multiple user actions
    // can trigger this event, and restartable resulted in hitching
    on<RefreshFormRequested>(_onRefreshForm, transformer: debounce(500));
    on<LoadCurrencyListsRequested>(
      _onLoadCurrencyLists,
      transformer: restartable(),
    );
    on<WatchOrderStatusRequested>(
      _onWatchOrderStatus,
      transformer: restartable(),
    );
  }

  final FiatRepository _fiatRepository;
  final CoinsBloc _coinsRepository;

  Future<void> _onChangeSelectedFiatCoin(
    SelectedFiatCurrencyChanged event,
    Emitter<FiatFormState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedFiat: CurrencyInput.dirty(event.selectedFiat),
      ),
    );
  }

  Future<void> _onChangeSelectedCoin(
    SelectedCoinChanged event,
    Emitter<FiatFormState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCoin: CurrencyInput.dirty(event.selectedCoin),
      ),
    );
  }

  Future<void> _onUpdateFiatAmount(
    FiatAmountChanged event,
    Emitter<FiatFormState> emit,
  ) async {
    emit(
      state.copyWith(
        fiatAmount: _getAmountInputWithBounds(event.fiatAmount),
      ),
    );
  }

  FiatAmountInput _getAmountInputWithBounds(
    String amount, {
    FiatPaymentMethod? selectedPaymentMethod,
  }) {
    double? minAmount;
    double? maxAmount;
    final paymentMethod = selectedPaymentMethod ?? state.selectedPaymentMethod;
    final firstLimit = paymentMethod.transactionLimits.firstOrNull;
    if (firstLimit != null) {
      minAmount = firstLimit.min;
      maxAmount = firstLimit.max;
    }

    return FiatAmountInput.dirty(
      amount,
      minValue: minAmount,
      maxValue: maxAmount,
    );
  }

  void _onSelectPaymentMethod(
    PaymentMethodSelected event,
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
    FormSubmissionRequested event,
    Emitter<FiatFormState> emit,
  ) async {
    final formValidationError = getFormIssue();
    if (formValidationError != null || !state.isValid) {
      log('Form validation failed. Validation: ${state.isValid}').ignore();
      return;
    }

    if (state.checkoutUrl.isNotEmpty) {
      emit(state.copyWith(checkoutUrl: ''));
    }

    try {
      final newOrder = await _fiatRepository.buyCoin(
        state.accountReference,
        state.selectedFiat.value!.symbol,
        state.selectedCoin.value!,
        state.coinReceiveAddress,
        state.selectedPaymentMethod,
        state.fiatAmount.value,
        BaseFiatProvider.successUrl(state.accountReference),
      );

      if (!newOrder.error.isNone) {
        return emit(_parseOrderError(newOrder.error));
      }

      final checkoutUrl = newOrder.checkoutUrl as String? ?? '';
      if (checkoutUrl.isEmpty) {
        log('Invalid checkout URL received.').ignore();
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
      log(
        'Error loading currency list: $e',
        path: 'FiatFormBloc._onSubmitForm',
        trace: s,
        isError: true,
      ).ignore();
      emit(
        state.copyWith(
          status: FiatFormStatus.failure,
          checkoutUrl: '',
        ),
      );
    }
  }

  Future<void> _onRefreshForm(
    RefreshFormRequested event,
    Emitter<FiatFormState> emit,
  ) async {
    // If the entered fiat amount is empty or invalid, then return a placeholder
    // list of payment methods
    String sourceAmount = '10000';
    if (state.fiatAmount.valueAsDouble == null ||
        state.fiatAmount.valueAsDouble == 0) {
      emit(_defaultPaymentMethods());
    } else {
      emit(state.copyWith(status: FiatFormStatus.loading));
      sourceAmount = state.fiatAmount.value;
    }

    emit(
      state.copyWith(
        fiatAmount: _getAmountInputWithBounds(state.fiatAmount.value),
      ),
    );

    // Prefetch required form data based on updated state information
    await _fetchAccountInfo(emit);
    try {
      final methods = _fiatRepository.getPaymentMethodsList(
        state.selectedFiat.value!.symbol,
        state.selectedCoin.value!,
        sourceAmount,
      );
      // await here in case of unhandled errors, but `onError` should handle
      // all exceptions/errors in the stream
      return await emit.forEach(
        methods,
        onData: (data) => _updatePaymentMethods(
          data,
          forceUpdate: event.forceRefresh,
        ),
        onError: (e, s) {
          log(
            'Error fetching and updating payment methods: $e',
            path: 'FiatFormBloc._onRefreshForm',
            trace: s,
            isError: true,
          ).ignore();
          return state.copyWith(paymentMethods: []);
        },
      );
    } catch (error, stacktrace) {
      log(
        'Error loading currency list: $error',
        path: 'FiatFormBloc._onRefreshForm',
        trace: stacktrace,
        isError: true,
      ).ignore();
      emit(
        state.copyWith(
          paymentMethods: [],
          status: FiatFormStatus.failure,
        ),
      );
    }
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

      return state.copyWith(
        status: FiatFormStatus.success,
      );
    } catch (e, s) {
      log(
        'Error loading currency list: $e',
        path: 'FiatFormBloc._onRefreshForm',
        trace: s,
        isError: true,
      ).ignore();
      return state.copyWith(paymentMethods: []);
    }
  }

  Future<void> _onAccountInformationChanged(
    AccountInformationChanged event,
    Emitter<FiatFormState> emit,
  ) async {
    final accountRerference = await _coinsRepository.getCoinAddress('KMD');
    final address = await _coinsRepository
        .getCoinAddress(state.selectedCoin.value!.getAbbr());

    emit(
      state.copyWith(
        accountReference: accountRerference,
        coinReceiveAddress: address,
      ),
    );
  }

  void _onClearAccountInformation(
    ClearAccountInformationRequested event,
    Emitter<FiatFormState> emit,
  ) {
    emit(
      state.copyWith(
        accountReference: '',
        coinReceiveAddress: '',
      ),
    );
  }

  Future<void> _fetchAccountInfo(Emitter<FiatFormState> emit) async {
    final address =
        await _coinsRepository.getCoinAddress(state.selectedCoin.value!.symbol);
    emit(
      state.copyWith(accountReference: address, coinReceiveAddress: address),
    );
  }

  void _onPaymentStatusMessage(
    FiatOnRampPaymentStatusMessageReceived event,
    Emitter<FiatFormState> emit,
  ) {
    if (!event.message.isJson()) {
      log('Invalid json console message received');
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
      if (_isRampNewPurchaseMessage(data)) {
        emit(state.copyWith(fiatOrderStatus: FiatOrderStatus.success));
      } else if (_isCheckoutStatusMessage(data)) {
        final status = data['status'] as String? ?? 'declined';
        emit(
          state.copyWith(
            fiatOrderStatus: FiatOrderStatus.fromString(status),
          ),
        );
      }
    } catch (e, s) {
      log(
        'Error parsing payment status message: $e',
        path: 'FiatFormBloc._onPaymentStatusMessage',
        trace: s,
        isError: true,
      ).ignore();
    }
  }

  void _onFiatModeChanged(FiatModeChanged event, Emitter<FiatFormState> emit) {
    emit(state.copyWith(fiatMode: event.mode));
  }

  Future<void> _onLoadCurrencyLists(
    LoadCurrencyListsRequested event,
    Emitter<FiatFormState> emit,
  ) async {
    try {
      final fiatList = await fiatRepository.getFiatList();
      final coinList = await fiatRepository.getCoinList();
      emit(state.copyWith(fiatList: fiatList, coinList: coinList));
    } catch (e, s) {
      log(
        'Error loading currency list: $e',
        path: 'FiatFormBloc._onLoadCurrencyLists',
        trace: s,
        isError: true,
      ).ignore();
    }
  }

  Future<void> _onWatchOrderStatus(
    WatchOrderStatusRequested event,
    Emitter<FiatFormState> emit,
  ) async {
    // banxa implementation monitors status using their API, so watch the order
    // status via the existing repository methods
    if (state.selectedPaymentMethod.providerId != 'Banxa') {
      return;
    }

    final orderStatusStream = _fiatRepository.watchOrderStatus(
      state.selectedPaymentMethod,
      state.orderId,
    );

    return emit.forEach(
      orderStatusStream,
      onData: (data) {
        return state.copyWith(fiatOrderStatus: data);
      },
      onError: (error, stackTrace) {
        log(
          'Error watching order status: $error',
          path: 'FiatFormBloc._onWatchOrderStatus',
          trace: stackTrace,
          isError: true,
        ).ignore();
        return state.copyWith(fiatOrderStatus: FiatOrderStatus.failed);
      },
    );
  }

  bool _isRampNewPurchaseMessage(Map<String, dynamic> data) {
    return data.containsKey('type') && data['type'] == 'PURCHASE_CREATED';
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
    if (!_coinsRepository.isLoggedIn) {
      return 'Please connect your wallet to purchase coins';
    }
    if (state.paymentMethods.isEmpty) {
      return 'No payment method for this pair';
    }
    if (state.coinReceiveAddress.isEmpty) {
      return 'No wallet, or coin/network might not be supported';
    }
    if (state.accountReference.isEmpty) {
      return 'Account reference (KMD Address) could not be fetched';
    }

    return null;
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
