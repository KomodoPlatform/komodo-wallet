import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_size.dart';

/// A widget that displays an asset's title, typically the asset name.
///
/// This replaces the previous CoinItemTitle component and works with AssetId instead of Coin.
class AssetItemTitle extends StatelessWidget {
  const AssetItemTitle({
    super.key,
    required this.assetId,
    required this.size,
    this.amount,
  });

  final AssetId? assetId;
  final AssetItemSize size;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: size.title,
            height: 1,
          ),
      child: Text(assetId?.name ?? 'Unknown Asset'),
    );
  }
}
