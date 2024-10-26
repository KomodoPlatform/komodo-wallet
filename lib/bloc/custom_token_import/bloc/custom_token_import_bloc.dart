import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_event.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_state.dart';
import 'package:web_dex/bloc/custom_token_import/data/custom_token_import_repository.dart';

class CustomTokenImportBloc
    extends Bloc<CustomTokenImportEvent, CustomTokenImportState> {
  final ICustomTokenImportRepository repository;

  CustomTokenImportBloc(this.repository)
      : super(const CustomTokenImportState()) {
    on<UpdateNetworkEvent>(_onUpdateAsset);
    on<UpdateAddressEvent>(_onUpdateAddress);
    on<UpdateDecimalsEvent>(_onUpdateDecimals);
    on<SubmitImportCustomTokenEvent>(_onSubmitImportCustomToken);
    on<SubmitFetchCustomTokenEvent>(_onSubmitFetchCustomToken);
    on<ResetFormStatusEvent>(_onResetFormStatus);
  }

  void _onResetFormStatus(
      ResetFormStatusEvent event, Emitter<CustomTokenImportState> emit) {
    emit(state.copyWith(
      formStatus: () => FormStatus.initial,
      formErrorMessage: () => null,
      importStatus: () => FormStatus.initial,
      importErrorMessage: () => null,
    ));
  }

  void _onUpdateAsset(
      UpdateNetworkEvent event, Emitter<CustomTokenImportState> emit) {
    emit(state.copyWith(network: () => event.network));
  }

  void _onUpdateAddress(
      UpdateAddressEvent event, Emitter<CustomTokenImportState> emit) {
    emit(state.copyWith(address: () => event.address));
  }

  void _onUpdateDecimals(
      UpdateDecimalsEvent event, Emitter<CustomTokenImportState> emit) {
    emit(state.copyWith(decimals: () => event.decimals));
  }

  Future<void> _onSubmitFetchCustomToken(SubmitFetchCustomTokenEvent event,
      Emitter<CustomTokenImportState> emit) async {
    emit(state.copyWith(formStatus: () => FormStatus.submitting));

    try {
      final tokenData = await repository.fetchCustomToken(
          state.network!.abbr, state.address!, state.decimals!);

      emit(state.copyWith(
        formStatus: () => FormStatus.success,
        tokenData: () => tokenData,
        formErrorMessage: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        formStatus: () => FormStatus.failure,
        formErrorMessage: () => e.toString(),
      ));
    }
  }

  Future<void> _onSubmitImportCustomToken(SubmitImportCustomTokenEvent event,
      Emitter<CustomTokenImportState> emit) async {
    emit(state.copyWith(importStatus: () => FormStatus.submitting));

    try {
      await repository.importCustomToken(
          state.network!.abbr, state.address!, state.decimals!);

      emit(state.copyWith(
        importStatus: () => FormStatus.success,
        importErrorMessage: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        importStatus: () => FormStatus.failure,
        importErrorMessage: () => e.toString(),
      ));
    }
  }
}
