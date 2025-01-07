import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/nft_withdraw/nft_withdraw_repo.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/convert_address/convert_address_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/errors.dart';
import 'package:web_dex/mm2/mm2_api/rpc/nft/withdraw/withdraw_nft_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/send_raw_transaction/send_raw_transaction_response.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/model/text_error.dart';

part 'nft_withdraw_event.dart';
part 'nft_withdraw_state.dart';

class NftWithdrawBloc extends Bloc<NftWithdrawEvent, NftWithdrawState> {
  NftWithdrawBloc({
    required NftWithdrawRepo repo,
    required NftToken nft,
    required Mm2Api mm2Api,
    required CoinsRepo coinsRepository,
  })  : _repo = repo,
        _coinsRepository = coinsRepository,
        _mm2Api = mm2Api,
        super(NftWithdrawFillState.initial(nft)) {
    on<NftWithdrawAddressChanged>(_onAddressChanged);
    on<NftWithdrawAmountChanged>(_onAmountChanged);
    on<NftWithdrawSendEvent>(_onSend);
    on<NftWithdrawConfirmSendEvent>(_onConfirmSend);
    on<NftWithdrawShowFillStep>(_onShowFillForm);
    on<NftWithdrawInit>(_onInit);
    on<NftWithdrawConvertAddress>(_onConvertAddress);
  }

  final NftWithdrawRepo _repo;
  final Mm2Api _mm2Api;
  final CoinsRepo _coinsRepository;

  Future<void> _onSend(
    NftWithdrawSendEvent event,
    Emitter<NftWithdrawState> emit,
  ) async {
    final state = this.state;
    if (state is! NftWithdrawFillState) return;
    if (state.isSending) return;

    emit(state.copyWith(
      isSending: () => true,
      addressError: () => null,
      amountError: () => null,
      sendError: () => null,
    ));
    final NftToken nft = state.nft;
    final String address = state.address;
    final int? amount = state.amount;

    await _activateParentCoinIfNeeded(nft);

    final BaseError? addressError =
        await _validateAddress(nft.parentCoin, address);
    final BaseError? amountError =
        _validateAmount(amount, int.parse(nft.amount), nft.contractType);
    if (addressError != null || amountError != null) {
      emit(state.copyWith(
        isSending: () => false,
        addressError: () => addressError,
        amountError: () => amountError,
      ));
      return;
    }

    try {
      final WithdrawNftResponse response =
          await _repo.withdraw(nft: nft, address: address, amount: amount);

      final NftTransactionDetails result = response.result;

      emit(NftWithdrawConfirmState(
        nft: state.nft,
        isSending: false,
        txDetails: result,
        sendError: null,
      ));
    } on ApiError catch (e) {
      emit(state.copyWith(sendError: () => e, isSending: () => false));
    } on TransportError catch (e) {
      emit(state.copyWith(sendError: () => e, isSending: () => false));
    } on ParsingApiJsonError catch (e) {
      if (kDebugMode) {
        print(e.message);
      }
      emit(state.copyWith(isSending: () => false));
    }
  }

  Future<void> _onConfirmSend(
      NftWithdrawConfirmSendEvent event, Emitter<NftWithdrawState> emit) async {
    final state = this.state;
    if (state is! NftWithdrawConfirmState) return;

    emit(state.copyWith(
      isSending: () => true,
      sendError: () => null,
    ));
    final txDetails = state.txDetails;

    final SendRawTransactionResponse response =
        await _repo.confirmSend(txDetails.coin, txDetails.txHex);
    final BaseError? responseError = response.error;
    final String? txHash = response.txHash;
    if (txHash == null) {
      emit(state.copyWith(
        isSending: () => false,
        sendError: () =>
            responseError ?? TextError(error: LocaleKeys.somethingWrong),
      ));
    } else {
      emit(NftWithdrawSuccessState(
        txHash: txHash,
        nft: state.nft,
        timestamp: txDetails.timestamp,
        to: txDetails.to.first,
      ));
    }
  }

  void _onAddressChanged(
      NftWithdrawAddressChanged event, Emitter<NftWithdrawState> emit) {
    final state = this.state;
    if (state is! NftWithdrawFillState) return;
    emit(state.copyWith(
      address: () => event.address,
      addressError: () => null,
      sendError: () => null,
    ));
  }

  void _onAmountChanged(
    NftWithdrawAmountChanged event,
    Emitter<NftWithdrawState> emit,
  ) {
    final state = this.state;
    if (state is! NftWithdrawFillState) return;

    emit(state.copyWith(
      amount: () => event.amount,
      amountError: () => null,
      sendError: () => null,
    ));
  }

  Future<BaseError?> _validateAddress(
    Coin coin,
    String address,
  ) async {
    if (address.isEmpty) {
      return TextError(error: LocaleKeys.invalidAddress.tr(args: [coin.abbr]));
    }
    try {
      final validateResponse = await _repo.validateAddress(coin, address);
      final isNonMixed = _isErcNonMixedCase(validateResponse.reason ?? '');

      if (isNonMixed) {
        return MixedCaseAddressError();
      }

      return validateResponse.isValid
          ? null
          : TextError(error: LocaleKeys.invalidAddress.tr(args: [coin.abbr]));
    } on ApiError catch (e) {
      return e;
    } catch (e) {
      return TextError(error: e.toString());
    }
  }

  BaseError? _validateAmount(
    int? amount,
    int totalAmount,
    NftContractType contractType,
  ) {
    if (contractType != NftContractType.erc1155) return null;
    if (amount == null || amount < 1) {
      return TextError(error: LocaleKeys.minCount.tr(args: ['1']));
    }
    if (amount > totalAmount) {
      return TextError(
          error: LocaleKeys.maxCount.tr(args: [totalAmount.toString()]));
    }
    return null;
  }

  FutureOr<void> _onShowFillForm(
      NftWithdrawShowFillStep event, Emitter<NftWithdrawState> emit) {
    final state = this.state;

    if (state is NftWithdrawConfirmState) {
      emit(NftWithdrawFillState(
        address: state.txDetails.to.first,
        amount: int.tryParse(state.txDetails.amount),
        isSending: false,
        nft: state.nft,
      ));
    } else {
      emit(NftWithdrawFillState.initial(state.nft));
    }
  }

  void _onInit(NftWithdrawInit event, Emitter<NftWithdrawState> emit) {
    if (isClosed) return;
    emit(NftWithdrawFillState.initial(state.nft));
  }

  bool _isErcNonMixedCase(String error) {
    return error.contains(LocaleKeys.invalidAddressChecksum.tr());
  }

  Future<void> _onConvertAddress(
      NftWithdrawConvertAddress event, Emitter<NftWithdrawState> emit) async {
    final state = this.state;
    if (state is! NftWithdrawFillState) return;

    final result = await _mm2Api.convertLegacyAddress(
      ConvertAddressRequest(
        coin: state.nft.parentCoin.abbr,
        from: state.address,
        isErc: state.nft.parentCoin.isErcType,
      ),
    );
    if (result == null) return;

    add(NftWithdrawAddressChanged(result));
  }

  Future<void> _activateParentCoinIfNeeded(NftToken nft) async {
    final parentCoin = state.nft.parentCoin;

    if (!parentCoin.isActive) {
      await _coinsRepository.activateCoinsSync([parentCoin]);
    }
  }
}
