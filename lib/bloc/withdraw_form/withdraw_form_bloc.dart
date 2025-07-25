import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:collection/collection.dart';

export 'package:web_dex/bloc/withdraw_form/withdraw_form_event.dart';
export 'package:web_dex/bloc/withdraw_form/withdraw_form_state.dart';
export 'package:web_dex/bloc/withdraw_form/withdraw_form_step.dart';

import 'package:decimal/decimal.dart';

class WithdrawFormBloc extends Bloc<WithdrawFormEvent, WithdrawFormState> {
  final KomodoDefiSdk _sdk;

  WithdrawFormBloc({
    required Asset asset,
    required KomodoDefiSdk sdk,
  })  : _sdk = sdk,
        super(
          WithdrawFormState(
            asset: asset,
            step: WithdrawFormStep.fill,
            recipientAddress: '',
            amount: '0',
          ),
        ) {
    on<WithdrawFormRecipientChanged>(_onRecipientChanged);
    on<WithdrawFormAmountChanged>(_onAmountChanged);
    on<WithdrawFormSourceChanged>(_onSourceChanged);
    on<WithdrawFormMaxAmountEnabled>(_onMaxAmountEnabled);
    on<WithdrawFormCustomFeeEnabled>(_onCustomFeeEnabled);
    on<WithdrawFormCustomFeeChanged>(_onFeeChanged);
    on<WithdrawFormMemoChanged>(_onMemoChanged);
    on<WithdrawFormIbcTransferEnabled>(_onIbcTransferEnabled);
    on<WithdrawFormIbcChannelChanged>(_onIbcChannelChanged);
    on<WithdrawFormPreviewSubmitted>(_onPreviewSubmitted);
    on<WithdrawFormSubmitted>(_onSubmitted);
    on<WithdrawFormCancelled>(_onCancelled);
    on<WithdrawFormReset>(_onReset);
    on<WithdrawFormSourcesLoadRequested>(_onSourcesLoadRequested);
    on<WithdrawFormConvertAddressRequested>(_onConvertAddress);

    add(const WithdrawFormSourcesLoadRequested());
  }

  Future<void> _onSourcesLoadRequested(
    WithdrawFormSourcesLoadRequested event,
    Emitter<WithdrawFormState> emit,
  ) async {
    try {
      final pubkeys = await state.asset.getPubkeys(_sdk);
      if (pubkeys.keys.isNotEmpty) {
        final current = state.selectedSourceAddress;
        final newSelection = current != null
            ? pubkeys.keys.firstWhereOrNull(
                  (key) => key.address == current.address,
                ) ??
                pubkeys.keys.first
            : (pubkeys.keys.length == 1 ? pubkeys.keys.first : null);

        emit(
          state.copyWith(
            pubkeys: () => pubkeys,
            networkError: () => null,
            selectedSourceAddress: () => newSelection,
          ),
        );
      } else {
        emit(
          state.copyWith(
            networkError: () => TextError(
              error: 'No addresses found for ${state.asset.id.name}',
            ),
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          networkError: () => TextError(error: 'Failed to load addresses: $e'),
        ),
      );
    }
  }

  FeeInfo? _getDefaultFee() {
    final protocol = state.asset.protocol;
    if (protocol is Erc20Protocol) {
      return FeeInfo.ethGas(
        coin: state.asset.id.id,
        gasPrice: Decimal.one,
        gas: 21000,
      );
    } else if (protocol is UtxoProtocol) {
      return FeeInfo.utxoFixed(
        coin: state.asset.id.id,
        amount: Decimal.fromInt(protocol.txFee ?? 10000),
      );
    }
    return null;
  }

  Future<void> _onRecipientChanged(
    WithdrawFormRecipientChanged event,
    Emitter<WithdrawFormState> emit,
  ) async {
    try {
      final trimmedAddress = event.address.trim();

      // Optimistically update the address and clear previous errors so the UI
      // reflects user input immediately. Validation results will update the
      // state again when available.
      emit(
        state.copyWith(
          recipientAddress: trimmedAddress,
          recipientAddressError: () => null,
        ),
      );

      // First check if it's an EVM address that needs conversion
      if (state.asset.protocol is Erc20Protocol &&
          _isValidEthAddressFormat(trimmedAddress) &&
          !_hasEthAddressMixedCase(trimmedAddress)) {
        try {
          // Try to convert to mixed case format if possible
          final result = await _sdk.addresses.convertFormat(
            asset: state.asset,
            address: trimmedAddress,
            format: const AddressFormat(format: 'mixedcase', network: ''),
          );

          // Validate the converted address
          final validationResult = await _sdk.addresses.validateAddress(
            asset: state.asset,
            address: result.convertedAddress,
          );
          final isMixedCaseAdddress = result.convertedAddress != trimmedAddress;

          if (validationResult.isValid) {
            emit(
              state.copyWith(
                recipientAddress: result.convertedAddress,
                recipientAddressError: () => null,
                isMixedCaseAddress: isMixedCaseAdddress,
              ),
            );
            return;
          }
        } catch (_) {
          // Conversion failed, continue with normal validation
        }
      }

      // Proceed with normal validation
      final validationResult = await _sdk.addresses.validateAddress(
        asset: state.asset,
        address: trimmedAddress,
      );
      if (!validationResult.isValid) {
        emit(
          state.copyWith(
            recipientAddress: trimmedAddress,
            recipientAddressError: () =>
                TextError(error: validationResult.invalidReason!),
            isMixedCaseAddress: false,
          ),
        );
        return;
      }

      // For non-EVM addresses
      emit(
        state.copyWith(
          recipientAddress: trimmedAddress,
          recipientAddressError: () => null,
          isMixedCaseAddress: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          recipientAddress: event.address.trim(),
          recipientAddressError: () =>
              TextError(error: 'Address validation failed: $e'),
          isMixedCaseAddress: false,
        ),
      );
    }
  }

  /// Checks if the address has valid Ethereum address format
  bool _isValidEthAddressFormat(String address) {
    return address.startsWith('0x') && address.length == 42;
  }

  void _onAmountChanged(
    WithdrawFormAmountChanged event,
    Emitter<WithdrawFormState> emit,
  ) {
    if (state.isMaxAmount) return;

    try {
      final amount = Decimal.parse(event.amount);
      // Use the selected address balance if available
      final balance = state.selectedSourceAddress?.balance.spendable;

      if (balance != null && amount > balance) {
        emit(
          state.copyWith(
            amount: event.amount,
            amountError: () => TextError(error: 'Insufficient funds'),
          ),
        );
        return;
      }

      if (amount <= Decimal.zero) {
        emit(
          state.copyWith(
            amount: event.amount,
            amountError: () =>
                TextError(error: 'Amount must be greater than 0'),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          amount: event.amount,
          amountError: () => null,
          previewError: () => null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          amount: event.amount,
          amountError: () => TextError(error: 'Invalid amount'),
        ),
      );
    }
  }

  void _onSourceChanged(
    WithdrawFormSourceChanged event,
    Emitter<WithdrawFormState> emit,
  ) {
    final balance = event.address.balance;
    final updatedAmount =
        state.isMaxAmount ? balance.spendable.toString() : state.amount;

    emit(
      state.copyWith(
        selectedSourceAddress: () => event.address,
        networkError: () => null,
        amount: updatedAmount,
        amountError: () => null,
        previewError: () => null,
      ),
    );

    // Re-validate the amount with the new source address balance
    if (!state.isMaxAmount) {
      add(WithdrawFormAmountChanged(updatedAmount));
    }
  }

  void _onMaxAmountEnabled(
    WithdrawFormMaxAmountEnabled event,
    Emitter<WithdrawFormState> emit,
  ) {
    final balance =
        state.selectedSourceAddress?.balance ?? state.pubkeys?.balance;
    final maxAmount =
        event.isEnabled ? (balance?.spendable.toString() ?? '0') : '0';

    emit(
      state.copyWith(
        isMaxAmount: event.isEnabled,
        amount: maxAmount,
        amountError: () => null,
        previewError: () => null, // Clear preview error when toggling max
      ),
    );
  }

  void _onCustomFeeEnabled(
    WithdrawFormCustomFeeEnabled event,
    Emitter<WithdrawFormState> emit,
  ) {
    // If enabling custom fees, set a default fee or reuse from `_getDefaultFee()`
    emit(
      state.copyWith(
        isCustomFee: event.isEnabled,
        customFee: event.isEnabled ? () => _getDefaultFee() : () => null,
        customFeeError: () => null,
      ),
    );
  }

  void _onFeeChanged(
    WithdrawFormCustomFeeChanged event,
    Emitter<WithdrawFormState> emit,
  ) {
    try {
      // Validate the new fee, e.g. if it's EthGas => check gasPrice, gas > 0, etc.
      if (event.fee is FeeInfoEthGas) {
        _validateEvmFee(event.fee as FeeInfoEthGas);
      } else if (event.fee is FeeInfoUtxoFixed) {
        _validateUtxoFee(event.fee as FeeInfoUtxoFixed);
      }
      emit(
        state.copyWith(
          customFee: () => event.fee,
          customFeeError: () => null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          customFeeError: () => TextError(error: e.toString()),
        ),
      );
    }
  }

  void _validateEvmFee(FeeInfoEthGas fee) {
    if (fee.gasPrice <= Decimal.zero) {
      throw Exception('Gas price must be greater than 0');
    }
    if (fee.gas <= 0) {
      throw Exception('Gas limit must be greater than 0');
    }
  }

  void _validateUtxoFee(FeeInfoUtxoFixed fee) {
    if (fee.amount <= Decimal.zero) {
      throw Exception('Fee amount must be greater than 0');
    }
  }

  void _onMemoChanged(
    WithdrawFormMemoChanged event,
    Emitter<WithdrawFormState> emit,
  ) {
    emit(state.copyWith(memo: () => event.memo));
  }

  void _onIbcTransferEnabled(
    WithdrawFormIbcTransferEnabled event,
    Emitter<WithdrawFormState> emit,
  ) {
    emit(
      state.copyWith(
        isIbcTransfer: event.isEnabled,
        ibcChannel: event.isEnabled ? () => state.ibcChannel : () => null,
        ibcChannelError: () => null,
      ),
    );
  }

  void _onIbcChannelChanged(
    WithdrawFormIbcChannelChanged event,
    Emitter<WithdrawFormState> emit,
  ) {
    if (event.channel.isEmpty) {
      emit(
        state.copyWith(
          ibcChannel: () => event.channel,
          ibcChannelError: () => TextError(error: LocaleKeys.enterIbcChannel.tr()),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        ibcChannel: () => event.channel,
        ibcChannelError: () => null,
      ),
    );
  }

  Future<void> _onPreviewSubmitted(
    WithdrawFormPreviewSubmitted event,
    Emitter<WithdrawFormState> emit,
  ) async {
    if (state.hasValidationErrors) return;

    try {
      emit(
        state.copyWith(
          isSending: true,
          previewError: () => null,
        ),
      );

      final preview = await _sdk.withdrawals.previewWithdrawal(
        state.toWithdrawParameters(),
      );

      emit(
        state.copyWith(
          preview: () => preview,
          step: WithdrawFormStep.confirm,
          isSending: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          previewError: () =>
              TextError(error: 'Failed to generate preview: $e'),
          isSending: false,
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    WithdrawFormSubmitted event,
    Emitter<WithdrawFormState> emit,
  ) async {
    if (state.hasValidationErrors) return;

    try {
      emit(
        state.copyWith(
          isSending: true,
          transactionError: () => null,
        ),
      );

      await for (final progress in _sdk.withdrawals.withdraw(
        state.toWithdrawParameters(),
      )) {
        if (progress.status == WithdrawalStatus.complete) {
          emit(
            state.copyWith(
              step: WithdrawFormStep.success,
              result: () => progress.withdrawalResult,
              isSending: false,
            ),
          );
          return;
        }

        if (progress.status == WithdrawalStatus.error) {
          throw Exception(progress.errorMessage);
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          transactionError: () => TextError(error: 'Transaction failed: $e'),
          step: WithdrawFormStep.failed,
          isSending: false,
        ),
      );
    }
  }

  void _onCancelled(
    WithdrawFormCancelled event,
    Emitter<WithdrawFormState> emit,
  ) {
    // TODO: Cancel withdrawal if in progress

    add(const WithdrawFormReset());
  }

  void _onReset(
    WithdrawFormReset event,
    Emitter<WithdrawFormState> emit,
  ) {
    emit(
      WithdrawFormState(
        asset: state.asset,
        step: WithdrawFormStep.fill,
        recipientAddress: '',
        amount: '0',
        pubkeys: state.pubkeys,
        selectedSourceAddress: state.pubkeys?.keys.first,
      ),
    );
  }

  bool _hasEthAddressMixedCase(String address) {
    if (!address.startsWith('0x')) return false;
    final chars = address.substring(2).split('');
    return chars.any((c) => c.toLowerCase() != c) &&
        chars.any((c) => c.toUpperCase() != c);
  }

  Future<void> _onConvertAddress(
    WithdrawFormConvertAddressRequested event,
    Emitter<WithdrawFormState> emit,
  ) async {
    if (state.isMixedCaseAddress) return;

    try {
      emit(state.copyWith(isSending: true));

      // For EVM addresses, we want to convert to checksum format
      final result = await _sdk.addresses.convertFormat(
        asset: state.asset,
        address: state.recipientAddress,
        format: const AddressFormat(format: 'mixedcase', network: ''),
      );

      emit(
        state.copyWith(
          recipientAddress: result.convertedAddress,
          isMixedCaseAddress: false,
          recipientAddressError: () => null,
          isSending: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          recipientAddressError: () =>
              TextError(error: 'Failed to convert address: $e'),
          isSending: false,
        ),
      );
    }
  }
}

class MixedCaseAddressError extends BaseError {
  @override
  String get message => LocaleKeys.mixedCaseError.tr();
}

class EvmAddressResult {
  final bool isValid;
  final bool isMixedCase;
  final String? errorMessage;

  EvmAddressResult({
    required this.isValid,
    this.isMixedCase = false,
    this.errorMessage,
  });

  bool get hasError => !isValid;
}
