part of 'trading_status_bloc.dart';

abstract class TradingStatusEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TradingStatusCheckRequested extends TradingStatusEvent {}
