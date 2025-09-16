import 'package:flutter/material.dart';

class LanguageLine extends StatelessWidget {
  const LanguageLine({
    required this.currentLocale,
    this.showChevron = false,
    this.flag,
    super.key,
  });

  final String currentLocale;
  final bool showChevron;
  final Widget? flag;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: showChevron ? 5 : 10,
      children: [
        if (flag != null) flag!,
        Padding(
          padding: const EdgeInsets.only(top: 1, left: 2),
          child: Text(
            currentLocale.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.labelLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (showChevron)
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: .5),
          ),
      ],
    );
  }
}
