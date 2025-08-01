import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_body.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_size.dart';

/// A widget that displays an asset with its logo and information.
///
/// This replaces the previous CoinItem and works with AssetId instead of Coin.
class AssetItem extends StatelessWidget {
  const AssetItem({
    super.key,
    required this.assetId,
    this.amount,
    this.size = AssetItemSize.medium,
    this.subtitleText,
  });

  final AssetId assetId;
  final double? amount;
  final AssetItemSize size;
  final String? subtitleText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssetLogo.ofId(
          assetId,
          size: size.assetLogo,
        ),
        SizedBox(width: 8),
        Flexible(
          child: AssetItemBody(
            assetId: assetId,
            amount: amount,
            size: size,
            subtitleText: subtitleText,
          ),
        ),
      ],
    );
  }
}
