import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticCard extends StatelessWidget {
  // Text shown under the stat value title. Uses default of bodySmall style.
  final Widget caption;

  // The value of the stat used for the title
  final double value;

  // The formatter used to format the value for the title
  final NumberFormat _valueFormatter;

  final VoidCallback? onPressed;

  final Widget footer;

  final Widget actionIcon;

  StatisticCard({
    super.key,
    required this.value,
    required this.caption,
    required this.footer,
    required this.actionIcon,
    NumberFormat? valueFormatter,
    this.onPressed,
  }) : _valueFormatter = valueFormatter ?? NumberFormat.currency(symbol: '\$');

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.from(
        colorScheme: Theme.of(context).colorScheme,
        useMaterial3: true,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: LimitedBox(
          maxHeight: 148,
          maxWidth: 300,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: RadialGradient(
                colors: [
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.25),
                  Colors.transparent,
                ],
                center: const Alignment(0.2, 0.1),
                radius: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          // color: Colors.white,
                          ),
                      child: Text(
                        _valueFormatter.format(value),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodySmall!,
                      child: caption,
                    ),
                    const Spacer(),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodySmall!,
                      child: footer,
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.topRight,
                  // TODO: Refactor this into re-usable button widget OR update
                  // app theme to use this style if this styling is used elsewhere
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: IconButton.filledTonal(
                      isSelected: false,
                      icon: actionIcon,
                      iconSize: 36,
                      onPressed: onPressed,
                    ),
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
