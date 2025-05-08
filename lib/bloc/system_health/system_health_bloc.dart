import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:web_dex/bloc/system_health/system_clock_repository.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/directly_connected_peers/get_directly_connected_peers.dart';

part 'system_health_event.dart';
part 'system_health_state.dart';

class SystemHealthBloc extends Bloc<SystemHealthEvent, SystemHealthState> {
  SystemHealthBloc(
    this._systemClockRepository,
    this._api, {
    Duration checkInterval = const Duration(seconds: 60),
  })  : _checkInterval = checkInterval,
        super(SystemHealthInitial()) {
    on<SystemHealthCheckRequested>(
      _onSystemHealthCheckRequested,
      transformer: restartable(),
    );
    on<SystemHealthPeriodicCheckStarted>(_onSystemHealthPeriodicCheckStarted);
    on<SystemHealthPeriodicCheckCancelled>(
      _onSystemHealthPeriodicCheckCancelled,
    );
    add(SystemHealthPeriodicCheckStarted());
  }

  Timer? _timer;
  final Duration _checkInterval;
  final SystemClockRepository _systemClockRepository;
  final Mm2Api _api;

  void _cancelPeriodicCheck() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _onSystemHealthPeriodicCheckStarted(
    SystemHealthPeriodicCheckStarted event,
    Emitter<SystemHealthState> emit,
  ) async {
    _cancelPeriodicCheck();

    add(SystemHealthCheckRequested());
    _timer = Timer.periodic(_checkInterval, (timer) {
      add(SystemHealthCheckRequested());
    });
  }

  Future<void> _onSystemHealthPeriodicCheckCancelled(
    SystemHealthPeriodicCheckCancelled event,
    Emitter<SystemHealthState> emit,
  ) async {
    _cancelPeriodicCheck();
  }

  Future<void> _onSystemHealthCheckRequested(
    SystemHealthCheckRequested event,
    Emitter<SystemHealthState> emit,
  ) async {
    emit(SystemHealthLoadInProgress());
    try {
      final bool systemClockValid =
          await _systemClockRepository.isSystemClockValid();
      final bool connectedPeersHealthy = await _arePeersConnected();
      final bool isSystemHealthy = systemClockValid || connectedPeersHealthy;

      emit(SystemHealthLoadSuccess(isSystemHealthy));
    } on Exception catch (_) {
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
      // do not prevent usage if no peers are connected
      // mm2 api is responsible for logging, so only return result here
      return false;
    }
  }

  @override
  Future<void> close() {
    _cancelPeriodicCheck();
    return super.close();
  }
}
