import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_size.dart';

/// A widget that displays an asset's subtitle, typically showing the ticker symbol.
///
/// This replaces the previous CoinItemSubtitle component and works with AssetId instead of Coin.
class AssetItemSubtitle extends StatelessWidget {
  const AssetItemSubtitle({
    super.key,
    required this.assetId,
    required this.size,
    this.amount,
    this.text,
  });

  final AssetId? assetId;
  final AssetItemSize size;
  final double? amount;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final String subtitleText =
        text ?? (assetId != null ? assetId!.symbol.configSymbol : 'Unknown');

    return Text(
      subtitleText,
      style: TextStyle(
        fontSize: size.subtitle,
        height: 1,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
