part of 'trading_status_bloc.dart';

abstract class TradingStatusEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

final class TradingStatusCheckRequested extends TradingStatusEvent {}

/// Event emitted when the bloc should start watching trading status continuously
final class TradingStatusWatchStarted extends TradingStatusEvent {}
