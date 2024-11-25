import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:web_dex/bloc/system_health/system_clock_repository.dart';
import 'package:web_dex/bloc/system_health/system_health_event.dart';
import 'package:web_dex/bloc/system_health/system_health_state.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/directly_connected_peers/get_directly_connected_peers.dart';

class SystemHealthBloc extends Bloc<SystemHealthEvent, SystemHealthState> {
  SystemHealthBloc(this._systemClockRepository, this._api)
      : super(SystemHealthInitial()) {
    on<CheckSystemClock>(_onCheckSystemClock);
    _startPeriodicCheck();
  }

  Timer? _timer;
  final SystemClockRepository _systemClockRepository;
  final Mm2Api _api;

  void _startPeriodicCheck() {
    add(CheckSystemClock());

    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      add(CheckSystemClock());
    });
  }

  Future<void> _onCheckSystemClock(
    CheckSystemClock event,
    Emitter<SystemHealthState> emit,
  ) async {
    emit(SystemHealthLoadInProgress());
    try {
      final bool systemClockValid =
          await _systemClockRepository.isSystemClockValid();
      final bool connectedPeersHealthy = await _arePeersConnected();
      final bool isSystemHealthy = systemClockValid || connectedPeersHealthy;

      emit(SystemHealthLoadSuccess(isSystemHealthy));
    } catch (_) {
      emit(SystemHealthLoadFailure());
    }
  }

  Future<bool> _arePeersConnected() async {
    try {
      final directlyConnectedPeers =
          await _api.getDirectlyConnectedPeers(GetDirectlyConnectedPeers());
      final connectedPeersHealthy = directlyConnectedPeers.peers.length >= 2;
      return connectedPeersHealthy;
    } on Exception catch (_) {
      // TODO: remove once the breaking rpc name change is in main
      try {
        final directlyConnectedPeers = await _api.getDirectlyConnectedPeers(
          GetDirectlyConnectedPeers(method: 'get_peers_info'),
        );
        final connectedPeersHealthy = directlyConnectedPeers.peers.length >= 2;
        return connectedPeersHealthy;
      } catch (_) {
        // fall through and return false
      }

      return false;
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
