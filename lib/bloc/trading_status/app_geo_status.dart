import 'package:equatable/equatable.dart' show Equatable;
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/trading_status/disallowed_feature.dart';

/// Structured status returned by the bouncer service.
class AppGeoStatus extends Equatable {
  const AppGeoStatus({
    this.disallowedAssets = const <AssetId>{},
    this.disallowedFeatures = const <DisallowedFeature>{},
  });

  /// Assets that are disallowed in the current geo location.
  final Set<AssetId> disallowedAssets;

  /// Features that are disallowed in the current geo location.
  final Set<DisallowedFeature> disallowedFeatures;

  /// Whether trading is enabled based on the current geo status.
  bool get tradingEnabled =>
      !disallowedFeatures.contains(DisallowedFeature.trading);

  bool isAssetBlocked(AssetId asset) {
    return disallowedAssets.contains(asset);
  }

  @override
  List<Object?> get props => [disallowedAssets, disallowedFeatures];
}
