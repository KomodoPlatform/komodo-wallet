import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_size.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/coin_sparkline.dart';

/// A widget that displays an asset in a list item format optimized for desktop devices.
///
/// This replaces the previous CoinListItemDesktop component and works with AssetId instead of Coin.
class AssetListItemDesktop extends StatelessWidget {
  const AssetListItemDesktop({
    super.key,
    required this.assetId,
    required this.backgroundColor,
    required this.onTap,
    this.priceChangePercentage24h,
  });

  final AssetId assetId;
  final Color backgroundColor;
  final void Function(AssetId) onTap;

  /// The 24-hour price change percentage for the asset
  final double? priceChangePercentage24h;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: () => onTap(assetId),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 200,
                    ),
                    alignment: Alignment.centerLeft,
                    child: AssetItem(
                      assetId: assetId,
                      size: AssetItemSize.large,
                    ),
                  ),
                ),
                // Spacer(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TrendPercentageText(
                      percentage: priceChangePercentage24h ?? 0,
                      showIcon: true,
                      iconSize: 16,
                      precision: 2,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: CoinSparkline(coinId: assetId.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
