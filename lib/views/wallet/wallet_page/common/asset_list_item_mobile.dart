import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_size.dart';

/// A widget that displays an asset in a list item format optimized for mobile devices.
///
/// This replaces the previous CoinListItemMobile component and works with AssetId instead of Coin.
class AssetListItemMobile extends StatelessWidget {
  const AssetListItemMobile({
    super.key,
    required this.assetId,
    required this.backgroundColor,
    required this.onTap,
  });

  final AssetId assetId;
  final Color backgroundColor;
  final void Function(AssetId) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(assetId),
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        child: Row(
          children: [
            Expanded(
              child: AssetItem(
                assetId: assetId,
                size: AssetItemSize.medium,
                heroTag: assetId.id,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
