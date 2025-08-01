import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/views/wallet/wallet_page/common/asset_list_item_desktop.dart';
import 'package:web_dex/views/wallet/wallet_page/common/asset_list_item_mobile.dart';

/// A widget that displays an asset in a list item format with different layouts for mobile and desktop.
///
/// This replaces the previous CoinListItem component and works with AssetId instead of Coin.
class AssetListItem extends StatelessWidget {
  const AssetListItem({
    super.key,
    required this.assetId,
    required this.backgroundColor,
    required this.onTap,
    this.onStatisticsTap,
    this.isActivating = false,
    this.priceChangePercentage24h,
  });

  final AssetId assetId;
  final Color backgroundColor;
  final void Function(AssetId) onTap;
  final void Function(AssetId, Duration period)? onStatisticsTap;
  final bool isActivating;
  final double? priceChangePercentage24h;

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: isActivating ? 0.3 : 1, child: _buildItem());
  }

  Widget _buildItem() {
    return isMobile
        ? AssetListItemMobile(
            assetId: assetId,
            backgroundColor: backgroundColor,
            onTap: onTap,
          )
        : AssetListItemDesktop(
            assetId: assetId,
            backgroundColor: backgroundColor,
            onTap: onTap,
            onStatisticsTap: onStatisticsTap,
          );
  }
}
