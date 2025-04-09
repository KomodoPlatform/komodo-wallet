import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_size.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_subtitle.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_title.dart';

/// A widget that displays an asset's title and subtitle information.
///
/// This replaces the previous CoinItemBody component and works with AssetId instead of Coin.
class AssetItemBody extends StatelessWidget {
  const AssetItemBody({
    super.key,
    required this.assetId,
    this.amount,
    this.size = AssetItemSize.medium,
    this.subtitleText,
  });

  final AssetId? assetId;
  final double? amount;
  final AssetItemSize size;
  final String? subtitleText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: size.verticalSpacing),
        AssetItemTitle(assetId: assetId, size: size, amount: amount),
        SizedBox(height: size.verticalSpacing),
        AssetItemSubtitle(
          assetId: assetId,
          size: size,
          amount: amount,
          text: subtitleText,
        ),
      ],
    );
  }
}
