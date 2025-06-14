import 'package:equatable/equatable.dart';

abstract class TradingBouncerEvent extends Equatable {
  const TradingBouncerEvent();

  @override
  List<Object?> get props => [];
}

class TradingBouncerCheckRequested extends TradingBouncerEvent {
  const TradingBouncerCheckRequested();
}
