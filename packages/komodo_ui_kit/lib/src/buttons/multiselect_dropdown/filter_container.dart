import 'package:flutter/material.dart';

enum UIChipState { empty, pressed, selected }

class UIChipColorScheme {
  final Color? emptyContainerColor;
  final Color? pressedContainerColor;
  final Color? selectedContainerColor;
  final Color? selectedTextColor;
  final Color? emptyTextColor;
  UIChipColorScheme({
    required this.emptyContainerColor,
    required this.pressedContainerColor,
    required this.selectedContainerColor,
    required this.selectedTextColor,
    required this.emptyTextColor,
  });
}

class UIChip extends StatelessWidget {
  final String title;
  final UIChipState status;
  final bool showIcon;
  final TextStyle? textStyle;
  final UIChipColorScheme colorScheme;

  const UIChip({
    super.key,
    required this.title,
    required this.status,
    required this.colorScheme,
    this.showIcon = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: getColor(context),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: (textStyle ?? Theme.of(context).textTheme.bodySmall)
                ?.copyWith(color: getTextColor(context)),
          ),
          const SizedBox(width: 4),
          if (showIcon)
            SizedBox(
              width: 12,
              child: Icon(
                UIChipState.pressed == status
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 12,
                color: getTextColor(context),
              ),
            ),
        ],
      ),
    );
  }

  Color? getColor(BuildContext context) {
    switch (status) {
      case UIChipState.empty:
        return colorScheme.emptyContainerColor;
      case UIChipState.pressed:
        return colorScheme.pressedContainerColor;
      case UIChipState.selected:
        return colorScheme.selectedContainerColor;
    }
  }

  Color? getTextColor(BuildContext context) {
    switch (status) {
      case UIChipState.empty:
      case UIChipState.pressed:
        return colorScheme.emptyTextColor;
      case UIChipState.selected:
        return colorScheme.selectedTextColor;
    }
  }
}
