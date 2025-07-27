import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_size.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/coin_sparkline.dart';
import 'package:app_theme/src/dark/theme_custom_dark.dart';
import 'package:app_theme/src/light/theme_custom_light.dart';

/// A widget that displays an asset in a list item format optimized for desktop devices.
///
/// This replaces the previous CoinListItemDesktop component and works with AssetId instead of Coin.
class AssetListItemDesktop extends StatelessWidget {
  const AssetListItemDesktop({
    super.key,
    required this.assetId,
    required this.backgroundColor,
    required this.onTap,
    this.onStatisticsTap,
    this.priceChangePercentage24h,
  });

  final AssetId assetId;
  final Color backgroundColor;
  final void Function(AssetId) onTap;
  final void Function(AssetId, Duration period)? onStatisticsTap;

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
                      heroTag: assetId.id,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: InkWell(
                      onTap: () => onStatisticsTap?.call(
                        assetId,
                        const Duration(days: 1),
                      ),
                      child: TrendPercentageText(
                        percentage: 23,
                        upColor: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .extension<ThemeCustomDark>()!
                                .increaseColor
                            : Theme.of(context)
                                .extension<ThemeCustomLight>()!
                                .increaseColor,
                        downColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context)
                                    .extension<ThemeCustomDark>()!
                                    .decreaseColor
                                : Theme.of(context)
                                    .extension<ThemeCustomLight>()!
                                    .decreaseColor,
                        value: 50,
                        valueFormatter: (value) =>
                            NumberFormat.currency(symbol: '\$').format(value),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => onStatisticsTap?.call(
                      assetId,
                      const Duration(days: 7),
                    ),
                    child: CoinSparkline(coinId: assetId.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
