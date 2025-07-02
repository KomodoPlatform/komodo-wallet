import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'trading_status_repository.dart';

part 'trading_status_event.dart';
part 'trading_status_state.dart';

class TradingStatusBloc extends Bloc<TradingStatusEvent, TradingStatusState> {
  TradingStatusBloc(this._repository) : super(TradingStatusInitial()) {
    on<TradingStatusCheckRequested>(_onCheckRequested);
  }

  final TradingStatusRepository _repository;

  // TODO (@takenagain): Retry periodically if the failure was caused by a
  // network issue.
  Future<void> _onCheckRequested(
    TradingStatusCheckRequested event,
    Emitter<TradingStatusState> emit,
  ) async {
    emit(TradingStatusLoadInProgress());
    try {
      final enabled = await _repository.isTradingEnabled();
      emit(enabled ? TradingEnabled() : TradingDisabled());

      // This catch will never be triggered by the repository. This will require
      // changes to meet the "TODO" above.
    } catch (_) {
      emit(TradingStatusLoadFailure());
    }
  }
}
