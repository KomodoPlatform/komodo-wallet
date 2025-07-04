import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/trading_kind/trading_kind.dart';
import 'package:komodo_wallet/bloc/trading_kind/trading_kind_event.dart';
import 'package:komodo_wallet/bloc/trading_kind/trading_kind_state.dart';

export 'package:komodo_wallet/bloc/trading_kind/trading_kind.dart';
export 'package:komodo_wallet/bloc/trading_kind/trading_kind_event.dart';
export 'package:komodo_wallet/bloc/trading_kind/trading_kind_state.dart';

class TradingKindBloc extends Bloc<TradingKindEvent, TradingKindState> {
  TradingKindBloc(super.initialState) {
    on<KindChanged>(_onKindChanged);
  }

  void setKind(TradingKind kind) => add(KindChanged(kind));

  void _onKindChanged(KindChanged event, Emitter<TradingKindState> emit) {
    emit(state.copyWith(kind: event.kind));
  }
}
