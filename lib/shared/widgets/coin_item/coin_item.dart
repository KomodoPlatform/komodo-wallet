import 'package:flutter/material.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_body.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:komodo_ui/komodo_ui.dart';

class CoinItem extends StatelessWidget {
  const CoinItem({
    required this.coin,
    super.key,
    this.amount,
    this.size = CoinItemSize.medium,
    this.subtitleText,
    this.showNetworkLogo = true,
    this.heroTag,
  });

  final Coin coin;
  final double? amount;
  final CoinItemSize size;
  final String? subtitleText;

  /// Optional tag used to animate the coin icon between routes.
  final Object? heroTag;

  /// Controls which icon widget to use for displaying the coin.
  ///
  /// When [true], uses AssetLogo.ofId which shows network-aware logos
  /// that may include protocol overlays for multi-chain assets.
  ///
  /// When [false], uses AssetIcon.ofTicker which shows simple asset icons
  /// without network context.
  final bool showNetworkLogo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showNetworkLogo)
          AssetLogo.ofId(
            coin.id,
            size: size.coinLogo,
            heroTag: heroTag,
          ),
        if (!showNetworkLogo)
          AssetIcon.ofTicker(
            coin.id.id,
            size: size.coinLogo,
            heroTag: heroTag,
          ),
        SizedBox(width: size.spacer),
        Flexible(
          child: CoinItemBody(
            coin: coin,
            amount: amount,
            size: size,
            subtitleText: subtitleText,
          ),
        ),
      ],
    );
  }
}
