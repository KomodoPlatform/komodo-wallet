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

  Future<void> _onCheckRequested(
    TradingStatusCheckRequested event,
    Emitter<TradingStatusState> emit,
  ) async {
    emit(TradingStatusLoadInProgress());
    try {
      final enabled = await _repository.isTradingEnabled();
      emit(enabled ? TradingEnabled() : TradingDisabled());
    } catch (_) {
      emit(TradingStatusLoadFailure());
    }
  }
}
