import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'auto_scroll_text.dart';

class StatisticCard extends StatelessWidget {
  // Text shown under the stat value title. Uses default of bodySmall style.
  final Widget caption;

  // The value of the stat used for the title
  final double value;

  // The formatter used to format the value for the title
  final NumberFormat _valueFormatter;

  final VoidCallback? onPressed;

  // Widget shown in the top right corner (typically TrendPercentageText)
  final Widget? trendWidget;

  // Optional action widget (button or text) shown in the middle-right area
  final Widget? actionWidget;

  StatisticCard({
    super.key,
    required this.value,
    required this.caption,
    this.trendWidget,
    this.actionWidget,
    NumberFormat? valueFormatter,
    this.onPressed,
  }) : _valueFormatter = valueFormatter ?? NumberFormat.currency(symbol: '\$');

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDarkMode ? Colors.black : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: Value and Caption
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Value
                    AutoScrollText(
                      text: _valueFormatter.format(value),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    // Caption
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodySmall!,
                      child: caption,
                    ),
                    if (actionWidget != null) ...[
                      const SizedBox(height: 8),
                      actionWidget!,
                    ],
                  ],
                ),
              ),
              // Right side: Trend widget (vertically centered)
              if (trendWidget != null) ...[
                const SizedBox(width: 8),
                trendWidget!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
