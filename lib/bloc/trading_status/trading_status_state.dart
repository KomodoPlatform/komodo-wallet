part of 'trading_status_bloc.dart';

abstract class TradingStatusState extends Equatable {
  @override
  List<Object?> get props => [];

  bool get isEnabled => this is TradingEnabled;
}

class TradingStatusInitial extends TradingStatusState {}

class TradingStatusLoadInProgress extends TradingStatusState {}

class TradingEnabled extends TradingStatusState {}

class TradingDisabled extends TradingStatusState {}

class TradingStatusLoadFailure extends TradingStatusState {}
