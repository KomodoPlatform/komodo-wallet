import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:web_dex/bloc/bitrefill/data/bitrefill_repository.dart';
import 'package:web_dex/bloc/bitrefill/models/bitrefill_payment_intent_event.dart';
import 'package:web_dex/model/coin.dart';

part 'bitrefill_event.dart';
part 'bitrefill_state.dart';

class BitrefillBloc extends Bloc<BitrefillEvent, BitrefillState> {
  BitrefillBloc()
      : _bitrefillRepository = BitrefillRepository(),
        super(BitrefillInitial()) {
    on<BitrefillLoadRequested>(_onBitrefillLoadRequested);
    on<BitrefillLaunchRequested>(_onBitrefillLaunchRequested);
    on<BitrefillPaymentIntentReceived>(_onBitrefillPaymentIntentReceived);
    on<BitrefillPaymentCompleted>(_onBitrefillPaymentCompleted);
  }

  final BitrefillRepository _bitrefillRepository;

  Future<void> _onBitrefillLoadRequested(
    BitrefillLoadRequested event,
    Emitter<BitrefillState> emit,
  ) async {
    emit(const BitrefillLoadInProgress());
    final String url = _bitrefillRepository.embeddedBitrefillUrl(
      coinAbbr: event.coin?.abbr,
      refundAddress: event.refundAddress ?? event.coin?.address,
    );

    final List<String> supportedCoins =
        _bitrefillRepository.bitrefillSupportedCoins;
    emit(BitrefillLoadSuccess(url, supportedCoins));
  }

  void _onBitrefillLaunchRequested(
    BitrefillEvent event,
    Emitter<BitrefillState> emit,
  ) {
    // previously handled payment intent watching here
  }

  void _onBitrefillPaymentIntentReceived(
    BitrefillPaymentIntentReceived event,
    Emitter<BitrefillState> emit,
  ) {
    emit(BitrefillPaymentInProgress(event.paymentIntentRecieved));
  }

  void _onBitrefillPaymentCompleted(
    BitrefillPaymentCompleted event,
    Emitter<BitrefillState> emit,
  ) {
    if (state is! BitrefillPaymentInProgress) {
      return;
    }

    final String invoiceId = (state as BitrefillPaymentInProgress)
        .paymentIntent
        .invoiceId
        .toString();
    emit(BitrefillPaymentSuccess(invoiceId: invoiceId));
  }
}
