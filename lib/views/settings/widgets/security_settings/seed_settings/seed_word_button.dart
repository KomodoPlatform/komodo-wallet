import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class SeedWordButton extends StatelessWidget {
  const SeedWordButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.isSelected,
  }) : super(key: key);
  final String text;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final opacity = isSelected ? 0.4 : 1.0;
    final themeData = Theme.of(context);
    final color = themeData.colorScheme.secondary;

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: 31,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: themeData.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(15),
              hoverColor: color.withValues(alpha: 0.05),
              highlightColor: color.withValues(alpha: 0.1),
              focusColor: color.withValues(alpha: 0.2),
              splashColor: color.withValues(alpha: 0.4),
              child: Stack(
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: _Text(
                      text: text,
                      isSelected: isSelected,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.close,
                        size: 13,
                        color: theme.custom.headerIconColor,
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({required this.text, required this.isSelected});
  final String text;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: theme.custom.headerIconColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}
