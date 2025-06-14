import 'package:bloc/bloc.dart';
import 'package:web_dex/services/trading_bouncer/trading_bouncer_service.dart';

part 'trading_bouncer_event.dart';
part 'trading_bouncer_state.dart';

class TradingBouncerBloc
    extends Bloc<TradingBouncerEvent, TradingBouncerState> {
  TradingBouncerBloc({required TradingBouncerService service})
    : _service = service,
      super(TradingBouncerState.initial()) {
    on<TradingBouncerCheckRequested>(_onCheckRequested);
    add(const TradingBouncerCheckRequested());
  }

  final TradingBouncerService _service;

  Future<void> _onCheckRequested(
    TradingBouncerCheckRequested event,
    Emitter<TradingBouncerState> emit,
  ) async {
    final walletOnly = await _service.checkTradingStatus();
    emit(state.copyWith(walletOnly: walletOnly));
  }
}
