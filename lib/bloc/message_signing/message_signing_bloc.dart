import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/bloc/message_signing/message_signing_event.dart';
import 'package:web_dex/bloc/message_signing/message_signing_state.dart';

class MessageSigningBloc
    extends Bloc<MessageSigningEvent, MessageSigningState> {
  final KomodoDefiSdk sdk;

  MessageSigningBloc(this.sdk) : super(MessageSigningState.initial()) {
    on<MessageSigningAddressesRequested>(_onLoadAddresses);
    on<MessageSigningAddressSelected>(_onSelectAddress);
    on<MessageSigningFormSubmitted>(_onSubmitMessage);
    on<MessageSigningInputConfirmed>(_onRequestConfirmation);
    on<MessageSigningConfirmationCancelled>(_onCancelConfirmation);
  }

  Future<void> _onLoadAddresses(
    MessageSigningAddressesRequested event,
    Emitter<MessageSigningState> emit,
  ) async {
    emit(state.copyWith(
        status: MessageSigningStatus.loading, errorMessage: null));

    try {
      final result = await sdk.pubkeys.getPubkeys(event.asset);
      final keys = result.keys;

      emit(state.copyWith(
        addresses: keys,
        selected: keys.isNotEmpty ? keys.first : null,
        status: MessageSigningStatus.ready,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MessageSigningStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onSelectAddress(
    MessageSigningAddressSelected event,
    Emitter<MessageSigningState> emit,
  ) {
    emit(state.copyWith(selected: event.address));
  }

  void _onRequestConfirmation(
    MessageSigningInputConfirmed event,
    Emitter<MessageSigningState> emit,
  ) {
    emit(state.copyWith(status: MessageSigningStatus.confirming));
  }

  void _onCancelConfirmation(
    MessageSigningConfirmationCancelled event,
    Emitter<MessageSigningState> emit,
  ) {
    emit(state.copyWith(status: MessageSigningStatus.ready));
  }

  Future<void> _onSubmitMessage(
    MessageSigningFormSubmitted event,
    Emitter<MessageSigningState> emit,
  ) async {
    final address = state.selected;
    if (address == null) {
      emit(state.copyWith(
        errorMessage: LocaleKeys.pleaseSelectAddress.tr(),
        status: MessageSigningStatus.failure,
      ));
      return;
    }

    emit(state.copyWith(
      status: MessageSigningStatus.submitting,
      errorMessage: null,
    ));

    try {
      final signed = await sdk.messageSigning.signMessage(
        coin: event.coinAbbr,
        address: address.address,
        message: event.message,
      );

      emit(state.copyWith(
        signedMessage: signed,
        status: MessageSigningStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: LocaleKeys.failedToSignMessage.tr(args: [e.toString()]),
        status: MessageSigningStatus.failure,
      ));
    }
  }
}
