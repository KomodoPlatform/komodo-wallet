import 'package:equatable/equatable.dart';
import 'package:komodo_wallet/bloc/trading_kind/trading_kind.dart';

abstract class TradingKindEvent extends Equatable {
  const TradingKindEvent();

  @override
  List<Object> get props => [];
}

class KindChanged extends TradingKindEvent {
  const KindChanged(this.kind);
  final TradingKind kind;
  @override
  List<Object> get props => [kind];
}
