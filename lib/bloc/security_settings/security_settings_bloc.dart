import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/bloc/security_settings/security_settings_state.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';

class SecuritySettingsBloc
    extends Bloc<SecuritySettingsEvent, SecuritySettingsState> {
  SecuritySettingsBloc(super.state, this.currentWalletBloc) {
    on<ResetEvent>(_onReset);
    on<ShowSeedEvent>(_onShowSeed);
    on<SeedConfirmEvent>(_onSeedConfirm);
    on<SeedConfirmedEvent>(_onSeedConfirmed);
    on<ShowSeedWordsEvent>(_onShowSeedWords);
    on<PasswordUpdateEvent>(_onPasswordUpdate);
    on<ShowSeedCopiedEvent>(_onSeedCopied);
  }

  final CurrentWalletBloc currentWalletBloc;

  void _onReset(
    ResetEvent event,
    Emitter<SecuritySettingsState> emit,
  ) {
    emit(SecuritySettingsState.initialState());
  }

  void _onShowSeed(
    ShowSeedEvent event,
    Emitter<SecuritySettingsState> emit,
  ) {
    final newState = state.copyWith(
      step: SecuritySettingsStep.seedShow,
      showSeedWords: false,
    );
    emit(newState);
  }

  Future<void> _onShowSeedWords(
    ShowSeedWordsEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    final isSeedSaved = state.isSeedSaved || event.isShow;
    if (isSeedSaved) {
      await currentWalletBloc.confirmBackup();
    }
    final newState = state.copyWith(
      step: SecuritySettingsStep.seedShow,
      showSeedWords: event.isShow,
      isSeedSaved: isSeedSaved,
    );
    emit(newState);
  }

  void _onPasswordUpdate(
    PasswordUpdateEvent event,
    Emitter<SecuritySettingsState> emit,
  ) {
    // TODO!: re-enable once password change is implemented
    // final newState = state.copyWith(
    //   step: SecuritySettingsStep.passwordUpdate,
    //   showSeedWords: false,
    // );
    // emit(newState);
    emit(state);
  }

  void _onSeedConfirm(
    SeedConfirmEvent event,
    Emitter<SecuritySettingsState> emit,
  ) {
    final newState = state.copyWith(
      step: SecuritySettingsStep.seedConfirm,
      showSeedWords: false,
    );
    emit(newState);
  }

  Future<void> _onSeedConfirmed(
    SeedConfirmedEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    await currentWalletBloc.confirmBackup();
    final newState = state.copyWith(
      step: SecuritySettingsStep.seedSuccess,
      showSeedWords: false,
    );
    emit(newState);
  }

  Future<void> _onSeedCopied(
    ShowSeedCopiedEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    await currentWalletBloc.confirmBackup();
    emit(state.copyWith(isSeedSaved: true));
  }
}
