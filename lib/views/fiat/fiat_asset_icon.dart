import 'package:flutter/material.dart';
import 'package:web_dex/bloc/fiat/models/i_currency.dart';
import 'package:web_dex/shared/widgets/coin_icon.dart';
import 'package:web_dex/views/fiat/fiat_icon.dart';

class FiatAssetIcon extends StatelessWidget {
  const FiatAssetIcon({
    required this.currency,
    required this.icon,
    required this.onTap,
    required this.assetExists,
    super.key,
  });

  final ICurrency currency;
  final Widget icon;
  final VoidCallback onTap;
  final bool? assetExists;

  @override
  Widget build(BuildContext context) {
    const double size = 36.0;

    if (currency.isFiat) {
      return FiatIcon(symbol: currency.symbol);
    }

    if (assetExists ?? false) {
      return CoinIcon(currency.symbol, size: size);
    } else {
      return icon;
    }
  }
}
