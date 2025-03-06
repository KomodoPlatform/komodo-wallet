import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/3p_api/faucet/faucet.dart' as api;
import 'package:web_dex/3p_api/faucet/faucet_response.dart';
import 'package:web_dex/bloc/faucet_button/faucet_button_event.dart';
import 'package:web_dex/bloc/faucet_button/faucet_button_state.dart';

class FaucetBloc extends Bloc<FaucetEvent, FaucetState> implements StateStreamable<FaucetState> {
  final KomodoDefiSdk kdfSdk;

  FaucetBloc({required this.kdfSdk}) : super(FaucetInitial()) {
    on<FaucetRequested>(_onFaucetRequest);
  }

  Future<void> _onFaucetRequest(
    FaucetRequested event,
    Emitter<FaucetState> emit,
  ) async {
    if (state is FaucetLoading) {
      final currentLoading = state as FaucetLoading;
      if (currentLoading.address == event.address) {
        return;
      }
    }

    emit(FaucetLoading(address: event.address));

    try {
      final response = await api.callFaucet(event.coinAbbr, event.address);

      if (response.status == FaucetStatus.success) {
        emit(FaucetSuccess(FaucetResponse(
          status: response.status,
          address: event.address,
          message: response.message,
          coin: event.coinAbbr,
        )));
      } else {
        emit(FaucetError("Faucet request failed: ${response.message}"));
      }
    } catch (error, stackTrace) {
      addError(error, stackTrace); // Properly logs errors
      emit(FaucetError("Network error: ${error.toString()}"));
    }
  }
}
