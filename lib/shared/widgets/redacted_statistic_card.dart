import 'package:flutter/material.dart';

class RedactedStatisticCard extends StatelessWidget {
  const RedactedStatisticCard({
    super.key,
    required this.caption,
    required this.footer,
    required this.actionIcon,
    this.onPressed,
  });

  final Widget caption;
  final Widget footer;
  final Widget actionIcon;
  final VoidCallback? onPressed;

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
                      .withOpacity(0.25),
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
                      style: Theme.of(context).textTheme.titleLarge!,
                      child: const Text('*****'),
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
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: IconButton.filledTonal(
                      isSelected: false,
                      icon: actionIcon,
                      iconSize: 42,
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
