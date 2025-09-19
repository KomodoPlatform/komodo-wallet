import 'package:flutter/material.dart';

class DexTextButton extends StatelessWidget {
  const DexTextButton({
    Key? key,
    required this.text,
    required this.isActive,
    this.onTap,
  }) : super(key: key);

  final String text;
  final bool isActive;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? (Color.lerp(theme.primaryColor, Colors.white, 0.1) ??
                    theme.primaryColor)
                : theme.disabledColor,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: isActive
                ? theme.primaryTextTheme.labelLarge?.color
                : theme.textTheme.labelLarge?.color,
          ),
        ),
      ),
    );
  }
}
