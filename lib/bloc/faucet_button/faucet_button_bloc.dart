import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/3p_api/faucet/faucet.dart' as api;
import 'package:web_dex/3p_api/faucet/faucet_response.dart';
import 'package:web_dex/bloc/faucet_button/faucet_button_event.dart';
import 'package:web_dex/views/wallet/coin_details/faucet/cubit/faucet_state.dart';

class FaucetBloc extends Bloc<FaucetRequested, FaucetState> {
  final KomodoDefiSdk kdfSdk;

  FaucetBloc({required this.kdfSdk}) : super(FaucetInitial()) {
    on<FaucetRequested>(_onFaucetRequest);
  }

  Future<void> _onFaucetRequest(
    FaucetRequested event,
    Emitter<FaucetState> emit,
  ) async {
    if (state is FaucetLoading) {
      print(
          "⚠️ Faucet request already in progress. Ignoring duplicate request.");
      return;
    }
    
    print("🚀 Processing faucet request for ${event.coinAbbr} - ${event.address}");
    emit(FaucetLoading());

    try {
      final response = await api.callFaucet(event.coinAbbr, event.address);
      print("✅ Faucet response received: ${response.message}");

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
    } catch (error) {
      emit(FaucetError("Network error: $error"));
    }
  }
}
