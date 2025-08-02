import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/3p_api/faucet/faucet.dart' as api;
import 'package:web_dex/3p_api/faucet/faucet_response.dart';
import 'package:web_dex/bloc/faucet_button/faucet_button_event.dart';
import 'package:web_dex/bloc/faucet_button/faucet_button_state.dart';
import 'package:logging/logging.dart';

class FaucetBloc extends Bloc<FaucetEvent, FaucetState>
    implements StateStreamable<FaucetState> {
  final _log = Logger('FaucetBloc');

  FaucetBloc() : super(FaucetInitial()) {
    on<FaucetRequested>(_onFaucetRequest);
  }

  Future<void> _onFaucetRequest(
    FaucetRequested event,
    Emitter<FaucetState> emit,
  ) async {
    if (state is FaucetRequestInProgress) {
      final currentLoading = state as FaucetRequestInProgress;
      if (currentLoading.address == event.address) {
        return;
      }
    }

    emit(FaucetRequestInProgress(address: event.address));

    try {
      final response = await api.callFaucet(event.coinAbbr, event.address);

      if (response.status == FaucetStatus.success) {
        emit(
          FaucetRequestSuccess(
            FaucetResponse(
              status: response.status,
              address: event.address,
              message: response.message,
              coin: event.coinAbbr,
            ),
          ),
        );
      } else {
        emit(FaucetRequestError("Faucet request failed: ${response.message}"));
      }
    } catch (error, stackTrace) {
      _log.shout('Faucet request failed', error, stackTrace);
      emit(FaucetRequestError("Network error: ${error.toString()}"));
    }
  }
}
