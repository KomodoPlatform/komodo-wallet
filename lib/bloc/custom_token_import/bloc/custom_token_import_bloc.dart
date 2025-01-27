import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_event.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_state.dart';
import 'package:web_dex/bloc/custom_token_import/data/custom_token_import_repository.dart';
import 'package:web_dex/model/coin_type.dart';

class CustomTokenImportBloc
    extends Bloc<CustomTokenImportEvent, CustomTokenImportState> {
  final ICustomTokenImportRepository repository;

  CustomTokenImportBloc(this.repository)
      : super(const CustomTokenImportState()) {
    on<UpdateNetworkEvent>(_onUpdateAsset);
    on<UpdateAddressEvent>(_onUpdateAddress);
    on<SubmitImportCustomTokenEvent>(_onSubmitImportCustomToken);
    on<SubmitFetchCustomTokenEvent>(_onSubmitFetchCustomToken);
    on<ResetFormStatusEvent>(_onResetFormStatus);
  }

  void _onResetFormStatus(
    ResetFormStatusEvent event,
    Emitter<CustomTokenImportState> emit,
  ) {
    final availableCoinTypes =
        CoinType.values.map((CoinType type) => type.toCoinSubClass());
    final items = CoinSubClass.values
        .where(
          (CoinSubClass type) =>
              type.isEvmProtocol() && availableCoinTypes.contains(type),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    emit(
      state.copyWith(
        formStatus: () => FormStatus.initial,
        formErrorMessage: () => null,
        importStatus: () => FormStatus.initial,
        importErrorMessage: () => null,
        evmNetworks: items,
      ),
    );
  }

  void _onUpdateAsset(
    UpdateNetworkEvent event,
    Emitter<CustomTokenImportState> emit,
  ) {
    if (event.network == null) {
      return;
    }
    emit(state.copyWith(network: () => event.network));
  }

  void _onUpdateAddress(
    UpdateAddressEvent event,
    Emitter<CustomTokenImportState> emit,
  ) {
    emit(state.copyWith(address: () => event.address));
  }

  Future<void> _onSubmitFetchCustomToken(
    SubmitFetchCustomTokenEvent event,
    Emitter<CustomTokenImportState> emit,
  ) async {
    emit(state.copyWith(formStatus: () => FormStatus.submitting));

    try {
      final tokenData =
          await repository.fetchCustomToken(state.network!, state.address!);

      emit(
        state.copyWith(
          formStatus: () => FormStatus.success,
          tokenData: () => tokenData,
          formErrorMessage: () => null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          formStatus: () => FormStatus.failure,
          tokenData: () => null,
          formErrorMessage: () => e.toString(),
        ),
      );
    }
  }

  Future<void> _onSubmitImportCustomToken(
    SubmitImportCustomTokenEvent event,
    Emitter<CustomTokenImportState> emit,
  ) async {
    emit(state.copyWith(importStatus: () => FormStatus.submitting));

    try {
      await repository.importCustomTokenLegacy(state.coin!);

      emit(
        state.copyWith(
          importStatus: () => FormStatus.success,
          importErrorMessage: () => null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          importStatus: () => FormStatus.failure,
          importErrorMessage: () => e.toString(),
        ),
      );
    }
  }
}
