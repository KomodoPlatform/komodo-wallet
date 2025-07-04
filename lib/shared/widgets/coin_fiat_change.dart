import 'package:flutter/material.dart';
import 'package:komodo_ui/src/defi/asset/trend_percentage_text.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:app_theme/src/dark/theme_custom_dark.dart';
import 'package:app_theme/src/light/theme_custom_light.dart';

class CoinFiatChange extends StatelessWidget {
  const CoinFiatChange(
    this.coin, {
    super.key,
    this.style,
    this.padding,
    this.useDashForCoinWithoutFiat = false,
  });

  final Coin coin;
  final bool useDashForCoinWithoutFiat;
  final TextStyle? style;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeCustom = Theme.of(context).brightness == Brightness.dark
        ? theme.extension<ThemeCustomDark>()!
        : theme.extension<ThemeCustomLight>()!;

    return Container(
      padding: padding,
      child: TrendPercentageText(
        percentage: coin.usdPrice?.change24h,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ).merge(style),
        upColor: themeCustom.increaseColor,
        downColor: themeCustom.decreaseColor,
        showIcon: false,
        noValueText: useDashForCoinWithoutFiat ? '' : '-',
      ),
    );
  }
}
