part of 'trading_status_bloc.dart';

abstract class TradingStatusState extends Equatable {
  @override
  List<Object?> get props => [];

  bool get isEnabled => this is TradingEnabled;
}

class TradingStatusInitial extends TradingStatusState {}

class TradingStatusLoadInProgress extends TradingStatusState {}

class TradingEnabled extends TradingStatusState {
  TradingEnabled({
    Set<AssetId>? disallowedAssets,
    Set<DisallowedFeature>? disallowedFeatures,
  })  : disallowedAssets = disallowedAssets ?? const <AssetId>{},
        disallowedFeatures = disallowedFeatures ?? const <DisallowedFeature>{};

  final Set<AssetId> disallowedAssets;
  final Set<DisallowedFeature> disallowedFeatures;

  @override
  List<Object?> get props => [disallowedAssets, disallowedFeatures];
}

class TradingDisabled extends TradingStatusState {
  TradingDisabled({
    Set<AssetId>? disallowedAssets,
    Set<DisallowedFeature>? disallowedFeatures,
  })  : disallowedAssets = disallowedAssets ?? const <AssetId>{},
        disallowedFeatures = disallowedFeatures ?? const <DisallowedFeature>{};

  final Set<AssetId> disallowedAssets;
  final Set<DisallowedFeature> disallowedFeatures;

  @override
  List<Object?> get props => [disallowedAssets, disallowedFeatures];
}

class TradingStatusLoadFailure extends TradingStatusState {}
