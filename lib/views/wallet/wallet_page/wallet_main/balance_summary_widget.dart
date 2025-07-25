import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:app_theme/src/dark/theme_custom_dark.dart';
import 'package:app_theme/src/light/theme_custom_light.dart';

/// Balance Summary Widget for mobile view
class BalanceSummaryWidget extends StatelessWidget {
  final double totalBalance;
  final double changeAmount;
  final double changePercentage;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BalanceSummaryWidget({
    super.key,
    required this.totalBalance,
    required this.changeAmount,
    required this.changePercentage,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          gradient: StatisticCard.containerGradient(theme),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total balance
            Text(
              '\$${NumberFormat("#,##0.00").format(totalBalance)}',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            // Change indicator using TrendPercentageText
            TrendPercentageText(
              percentage: changePercentage,
              upColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context)
                      .extension<ThemeCustomDark>()!
                      .increaseColor
                  : Theme.of(context)
                      .extension<ThemeCustomLight>()!
                      .increaseColor,
              downColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context)
                      .extension<ThemeCustomDark>()!
                      .decreaseColor
                  : Theme.of(context)
                      .extension<ThemeCustomLight>()!
                      .decreaseColor,
              value: changeAmount,
              valueFormatter: (value) =>
                  NumberFormat.currency(symbol: '\$').format(value),
            ),
          ],
        ),
      ),
    );
  }
}
