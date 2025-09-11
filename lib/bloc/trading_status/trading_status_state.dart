part of 'trading_status_bloc.dart';

abstract class TradingStatusState extends Equatable {
  @override
  List<Object?> get props => [];

  bool get isEnabled => this is TradingEnabled;

  /// Set of features that are currently disallowed for the user, e.g.,
  /// {'TRADING', 'PRIVACY_COINS'}. Defaults to empty for non-loaded states.
  Set<String> get disallowedFeatures => const {};
}

class TradingStatusInitial extends TradingStatusState {}

class TradingStatusLoadInProgress extends TradingStatusState {}

class TradingEnabled extends TradingStatusState {
  TradingEnabled({Set<String>? disallowedFeatures})
      : _disallowedFeatures = disallowedFeatures ?? const {};

  final Set<String> _disallowedFeatures;

  @override
  List<Object?> get props => [_disallowedFeatures];

  @override
  Set<String> get disallowedFeatures => _disallowedFeatures;
}

class TradingDisabled extends TradingStatusState {
  TradingDisabled({Set<String>? disallowedFeatures})
      : _disallowedFeatures = disallowedFeatures ?? const {};

  final Set<String> _disallowedFeatures;

  @override
  List<Object?> get props => [_disallowedFeatures];

  @override
  Set<String> get disallowedFeatures => _disallowedFeatures;
}

class TradingStatusLoadFailure extends TradingStatusState {}
