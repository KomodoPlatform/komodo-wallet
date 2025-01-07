import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_event.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_state.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_step.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/convert_address/convert_address_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/send_raw_transaction/send_raw_transaction_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/withdraw/trezor_withdraw/trezor_withdraw_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/validateaddress/validateaddress_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/fee/fee_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/withdraw_request.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/fee_type.dart';
import 'package:web_dex/model/hw_wallet/trezor_progress_status.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/model/withdraw_details/withdraw_details.dart';
import 'package:web_dex/shared/utils/utils.dart';

export 'package:web_dex/bloc/withdraw_form/withdraw_form_event.dart';
export 'package:web_dex/bloc/withdraw_form/withdraw_form_state.dart';
export 'package:web_dex/bloc/withdraw_form/withdraw_form_step.dart';

class WithdrawFormBloc extends Bloc<WithdrawFormEvent, WithdrawFormState> {
  WithdrawFormBloc({
    required Coin coin,
    required CoinsRepo coinsRepository,
    required Mm2Api api,
    required this.goBack,
  })  : _coinsRepo = coinsRepository,
        _mm2Api = api,
        super(WithdrawFormState.initial(coin, coinsRepository)) {
    on<WithdrawFormAddressChanged>(_onAddressChanged);
    on<WithdrawFormAmountChanged>(_onAmountChanged);
    on<WithdrawFormCustomFeeChanged>(_onCustomFeeChanged);
    on<WithdrawFormCustomEvmFeeChanged>(_onCustomEvmFeeChanged);
    on<WithdrawFormSenderAddressChanged>(_onSenderAddressChanged);
    on<WithdrawFormMaxTapped>(_onMaxTapped);
    on<WithdrawFormSubmitted>(_onSubmitted);
    on<WithdrawFormWithdrawSuccessful>(_onWithdrawSuccess);
    on<WithdrawFormWithdrawFailed>(_onWithdrawFailed);
    on<WithdrawFormSendRawTx>(_onSendRawTransaction);
    on<WithdrawFormCustomFeeEnabled>(_onCustomFeeEnabled);
    on<WithdrawFormCustomFeeDisabled>(_onCustomFeeDisabled);
    on<WithdrawFormConvertAddress>(_onConvertMixedCaseAddress);
    on<WithdrawFormStepReverted>(_onStepReverted);
    on<WithdrawFormReset>(_onWithdrawFormReset);
    on<WithdrawFormTrezorStatusUpdated>(_onTrezorProgressUpdated);
    on<WithdrawFormMemoUpdated>(_onMemoUpdated);
  }

  // will use actual CoinsRepo when implemented
  final CoinsRepo _coinsRepo;
  final Mm2Api _mm2Api;
  final VoidCallback goBack;

  // Event handlers
  void _onAddressChanged(
    WithdrawFormAddressChanged event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(state.copyWith(address: event.address));
  }

  void _onAmountChanged(
    WithdrawFormAmountChanged event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(state.copyWith(amount: event.amount, isMaxAmount: false));
  }

  void _onCustomFeeEnabled(
    WithdrawFormCustomFeeEnabled event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(state.copyWith(
        isCustomFeeEnabled: true, customFee: FeeRequest(type: _customFeeType)));
  }

  void _onCustomFeeDisabled(
    WithdrawFormCustomFeeDisabled event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(state.copyWith(
      isCustomFeeEnabled: false,
      customFee: FeeRequest(type: _customFeeType),
      gasLimitError: TextError.empty(),
      gasPriceError: TextError.empty(),
      utxoCustomFeeError: TextError.empty(),
    ));
  }

  void _onCustomFeeChanged(
    WithdrawFormCustomFeeChanged event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(state.copyWith(
      customFee: FeeRequest(
        type: feeType.utxoFixed,
        amount: event.amount,
      ),
    ));
  }

  void _onCustomEvmFeeChanged(
    WithdrawFormCustomEvmFeeChanged event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(state.copyWith(
      customFee: FeeRequest(
        type: feeType.ethGas,
        gas: event.gas,
        gasPrice: event.gasPrice,
      ),
    ));
  }

  void _onSenderAddressChanged(
    WithdrawFormSenderAddressChanged event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(
      state.copyWith(
        selectedSenderAddress: event.address,
        amount: state.isMaxAmount
            ? doubleToString(
                state.coin.getHdAddress(event.address)?.balance.spendable ??
                    0.0)
            : state.amount,
      ),
    );
  }

  void _onMaxTapped(
    WithdrawFormMaxTapped event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(state.copyWith(
      amount: event.isEnabled ? doubleToString(state.senderAddressBalance) : '',
      isMaxAmount: event.isEnabled,
    ));
  }

  Future<void> _onSubmitted(
    WithdrawFormSubmitted event,
    Emitter<WithdrawFormState> emitter,
  ) async {
    if (state.isSending) return;
    emitter(state.copyWith(
      isSending: true,
      trezorProgressStatus: null,
      sendError: TextError.empty(),
      amountError: TextError.empty(),
      addressError: TextError.empty(),
      gasLimitError: TextError.empty(),
      gasPriceError: TextError.empty(),
      utxoCustomFeeError: TextError.empty(),
    ));

    bool isValid = await _validateEnterForm(emitter);
    if (!isValid) {
      return;
    }

    isValid = await _additionalValidate(emitter);
    if (!isValid) {
      emitter(state.copyWith(isSending: false));
      return;
    }

    final withdrawResponse = state.coin.enabledType == WalletType.trezor
        ? await _coinsRepo.trezor.withdraw(
            TrezorWithdrawRequest(
              coin: state.coin,
              from: state.selectedSenderAddress,
              to: state.address,
              amount: state.isMaxAmount
                  ? state.senderAddressBalance
                  : double.parse(state.amount),
              max: state.isMaxAmount,
              fee: state.isCustomFeeEnabled ? state.customFee : null,
            ),
            onProgressUpdated: (TrezorProgressStatus? status) {
              add(WithdrawFormTrezorStatusUpdated(status: status));
            },
          )
        : await _coinsRepo.withdraw(WithdrawRequest(
            to: state.address,
            coin: state.coin.abbr,
            max: state.isMaxAmount,
            amount: state.isMaxAmount ? null : state.amount,
            memo: state.memo,
            fee: state.isCustomFeeEnabled
                ? state.customFee
                : state.coin.type == CoinType.cosmos ||
                        state.coin.type == CoinType.iris
                    ? FeeRequest(
                        type: feeType.cosmosGas,
                        gasLimit: 150000,
                        gasPrice: 0.05,
                      )
                    : null,
          ));

    final BaseError? error = withdrawResponse.error;
    final WithdrawDetails? result = withdrawResponse.result;

    if (error != null) {
      add(WithdrawFormWithdrawFailed(error: error));
      log('WithdrawFormBloc: withdraw error: ${error.message}', isError: true);
      return;
    }

    if (result == null) {
      emitter(state.copyWith(
        sendError: TextError(error: LocaleKeys.somethingWrong.tr()),
        isSending: false,
      ));
      return;
    }

    add(WithdrawFormWithdrawSuccessful(details: result));
  }

  void _onWithdrawSuccess(
    WithdrawFormWithdrawSuccessful event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(state.copyWith(
      isSending: false,
      withdrawDetails: event.details,
      step: WithdrawFormStep.confirm,
    ));
  }

  void _onWithdrawFailed(
    WithdrawFormWithdrawFailed event,
    Emitter<WithdrawFormState> emitter,
  ) {
    final error = event.error;

    emitter(state.copyWith(
      sendError: error,
      isSending: false,
      step: WithdrawFormStep.failed,
    ));
  }

  void _onTrezorProgressUpdated(
    WithdrawFormTrezorStatusUpdated event,
    Emitter<WithdrawFormState> emitter,
  ) {
    String? message;

    switch (event.status) {
      case TrezorProgressStatus.waitingForUserToConfirmSigning:
        message = LocaleKeys.confirmOnTrezor.tr();
        break;
      default:
    }

    if (state.trezorProgressStatus != message) {
      emitter(state.copyWith(trezorProgressStatus: message));
    }
  }

  Future<void> _onConvertMixedCaseAddress(
    WithdrawFormConvertAddress event,
    Emitter<WithdrawFormState> emitter,
  ) async {
    final result = await _mm2Api.convertLegacyAddress(
      ConvertAddressRequest(
        coin: state.coin.abbr,
        from: state.address,
        isErc: state.coin.isErcType,
      ),
    );

    add(WithdrawFormAddressChanged(address: result ?? ''));
  }

  Future<void> _onSendRawTransaction(
    WithdrawFormSendRawTx event,
    Emitter<WithdrawFormState> emitter,
  ) async {
    if (state.isSending) return;
    emitter(state.copyWith(isSending: true, sendError: TextError.empty()));
    final BaseError? parentCoinError = _checkParentCoinErrors(
      coin: state.coin,
      fee: state.withdrawDetails.feeValue,
    );
    if (parentCoinError != null) {
      emitter(state.copyWith(
        isSending: false,
        sendError: parentCoinError,
      ));
      return;
    }

    final response = await _mm2Api.sendRawTransaction(
      SendRawTransactionRequest(
        coin: state.withdrawDetails.coin,
        txHex: state.withdrawDetails.txHex,
      ),
    );

    final BaseError? responseError = response.error;
    final String? txHash = response.txHash;

    if (responseError != null) {
      log(
        'WithdrawFormBloc: sendRawTransaction error: ${responseError.message}',
        isError: true,
      );
      emitter(state.copyWith(
        isSending: false,
        sendError: responseError,
        step: WithdrawFormStep.failed,
      ));
      return;
    }

    if (txHash == null) {
      emitter(state.copyWith(
        isSending: false,
        sendError: TextError(error: LocaleKeys.somethingWrong.tr()),
        step: WithdrawFormStep.failed,
      ));
      return;
    }
    emitter(state.copyWith(step: WithdrawFormStep.success));
  }

  void _onStepReverted(
    WithdrawFormStepReverted event,
    Emitter<WithdrawFormState> emitter,
  ) {
    if (event.step == WithdrawFormStep.confirm) {
      emitter(
        state.copyWith(
          step: WithdrawFormStep.fill,
          withdrawDetails: WithdrawDetails.empty(),
        ),
      );
    }
  }

  void _onMemoUpdated(
    WithdrawFormMemoUpdated event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(state.copyWith(memo: event.text));
  }

  void _onWithdrawFormReset(
    WithdrawFormReset event,
    Emitter<WithdrawFormState> emitter,
  ) {
    emitter(WithdrawFormState.initial(state.coin, _coinsRepo));
  }

  String get _customFeeType =>
      state.coin.type == CoinType.smartChain || state.coin.type == CoinType.utxo
          ? feeType.utxoFixed
          : feeType.ethGas;

  // Validators
  Future<bool> _additionalValidate(Emitter<WithdrawFormState> emitter) async {
    final BaseError? parentCoinError = _checkParentCoinErrors(coin: state.coin);
    if (parentCoinError != null) {
      emitter(state.copyWith(sendError: parentCoinError));
      return false;
    }
    return true;
  }

  Future<bool> _validateEnterForm(Emitter<WithdrawFormState> emitter) async {
    final bool isAddressValid = await _validateAddress(emitter);
    final bool isAmountValid = _validateAmount(emitter);
    final bool isCustomFeeValid = _validateCustomFee(emitter);

    return isAddressValid && isAmountValid && isCustomFeeValid;
  }

  Future<bool> _validateAddress(Emitter<WithdrawFormState> emitter) async {
    final String address = state.address;
    if (address.isEmpty) {
      emitter(state.copyWith(
        isSending: false,
        addressError: TextError(
            error: LocaleKeys.invalidAddress.tr(args: [state.coin.abbr])),
      ));
      return false;
    }
    if (state.coin.enabledType == WalletType.trezor &&
        state.selectedSenderAddress.isEmpty) {
      emitter(state.copyWith(
        isSending: false,
        addressError: TextError(error: LocaleKeys.noSenderAddress.tr()),
      ));
      return false;
    }

    final Map<String, dynamic>? validateRawResponse =
        await _mm2Api.validateAddress(
      state.coin.abbr,
      state.address,
    );
    if (validateRawResponse == null) {
      emitter(state.copyWith(
        isSending: false,
        addressError: TextError(
            error: LocaleKeys.invalidAddress.tr(args: [state.coin.abbr])),
      ));
      return false;
    }

    final ValidateAddressResponse validateResponse =
        ValidateAddressResponse.fromJson(validateRawResponse);

    final reason = validateResponse.reason ?? '';
    final isNonMixed = _isErcNonMixedCase(reason);
    final isValid = validateResponse.isValid;

    if (isNonMixed) {
      emitter(state.copyWith(
        isSending: false,
        addressError: MixedCaseAddressError(),
      ));
      return false;
    } else if (!isValid) {
      emitter(state.copyWith(
        isSending: false,
        addressError: TextError(
            error: LocaleKeys.invalidAddress.tr(args: [state.coin.abbr])),
      ));
      return false;
    }

    emitter(state.copyWith(
      addressError: TextError.empty(),
      amountError: state.amountError,
    ));
    return true;
  }

  bool _isErcNonMixedCase(String error) {
    if (!state.coin.isErcType) return false;
    if (!error.contains(LocaleKeys.invalidAddressChecksum.tr())) return false;
    return true;
  }

  bool _validateAmount(Emitter<WithdrawFormState> emitter) {
    if (state.amount.isEmpty) {
      emitter(state.copyWith(
          isSending: false,
          amountError: TextError(
            error: LocaleKeys.enterAmountToSend.tr(args: [state.coin.abbr]),
          )));
      return false;
    }
    final double? parsedValue = double.tryParse(state.amount);

    if (parsedValue == null) {
      emitter(state.copyWith(
          isSending: false,
          amountError: TextError(
            error: LocaleKeys.enterAmountToSend.tr(args: [state.coin.abbr]),
          )));
      return false;
    }

    if (parsedValue == 0) {
      emitter(state.copyWith(
          isSending: false,
          amountError: TextError(
            error: LocaleKeys.inferiorSendAmount.tr(args: [state.coin.abbr]),
          )));
      return false;
    }

    final double formattedBalance =
        double.parse(doubleToString(state.senderAddressBalance));

    if (parsedValue > formattedBalance) {
      emitter(state.copyWith(
          isSending: false,
          amountError: TextError(
            error: LocaleKeys.notEnoughBalance.tr(),
          )));
      return false;
    }

    if (state.isCustomFeeEnabled &&
        !state.isMaxAmount &&
        state.customFee.type == feeType.utxoFixed) {
      final double feeValue =
          double.tryParse(state.customFee.amount ?? '0.0') ?? 0.0;
      if ((parsedValue + feeValue) > formattedBalance) {
        emitter(state.copyWith(
            isSending: false,
            amountError: TextError(
              error: LocaleKeys.notEnoughBalance.tr(),
            )));
        return false;
      }
    }

    return true;
  }

  bool _validateCustomFee(Emitter<WithdrawFormState> emitter) {
    final customFee = state.customFee;
    if (!state.isCustomFeeEnabled) {
      return true;
    }
    if (customFee.type == feeType.utxoFixed) {
      return _validateUtxoCustomFee(emitter);
    }
    if (customFee.type == feeType.ethGas) {
      return _validateEvmCustomFee(emitter);
    }
    return true;
  }

  bool _validateUtxoCustomFee(Emitter<WithdrawFormState> emitter) {
    final value = state.customFee.amount;
    final double? feeAmount = _valueToAmount(value);
    if (feeAmount == null || feeAmount < 0) {
      emitter(state.copyWith(
          isSending: false,
          utxoCustomFeeError:
              TextError(error: LocaleKeys.pleaseInputData.tr())));
      return false;
    }
    final double amountToSend = state.amountToSendDouble;

    if (feeAmount > amountToSend) {
      emitter(state.copyWith(
          isSending: false,
          utxoCustomFeeError:
              TextError(error: LocaleKeys.customFeeHigherAmount.tr())));
      return false;
    }

    return true;
  }

  bool _validateEvmCustomFee(Emitter<WithdrawFormState> emitter) {
    final bool isGasLimitValid = _gasLimitValidator(emitter);
    final bool isGasPriceValid = _gasPriceValidator(emitter);
    return isGasLimitValid && isGasPriceValid;
  }

  BaseError? _checkParentCoinErrors({required Coin? coin, String? fee}) {
    final Coin? parentCoin = coin?.parentCoin;
    if (parentCoin == null) return null;

    if (!parentCoin.isActive) {
      return TextError(
          error:
              LocaleKeys.withdrawNoParentCoinError.tr(args: [parentCoin.abbr]));
    }

    final double balance = parentCoin.balance;

    if (balance == 0) {
      return TextError(
        error: LocaleKeys.withdrawTopUpBalanceError.tr(args: [parentCoin.abbr]),
      );
    } else if (fee != null && parentCoin.balance < double.parse(fee)) {
      return TextError(
        error: LocaleKeys.withdrawNotEnoughBalanceForGasError
            .tr(args: [parentCoin.abbr]),
      );
    }

    return null;
  }

  bool _gasLimitValidator(Emitter<WithdrawFormState> emitter) {
    final value = state.customFee.gas.toString();
    final double? feeAmount = _valueToAmount(value);
    if (feeAmount == null || feeAmount < 0) {
      emitter(state.copyWith(
          isSending: false,
          gasLimitError: TextError(error: LocaleKeys.pleaseInputData.tr())));
      return false;
    }
    return true;
  }

  bool _gasPriceValidator(Emitter<WithdrawFormState> emitter) {
    final value = state.customFee.gasPrice;
    final double? feeAmount = _valueToAmount(value);
    if (feeAmount == null || feeAmount < 0) {
      emitter(state.copyWith(
          isSending: false,
          gasPriceError: TextError(error: LocaleKeys.pleaseInputData.tr())));
      return false;
    }
    return true;
  }

  double? _valueToAmount(String? value) {
    if (value == null) return null;
    value = value.replaceAll(',', '.');
    return double.tryParse(value);
  }
}

class MixedCaseAddressError extends BaseError {
  @override
  String get message => LocaleKeys.mixedCaseError.tr();
}
