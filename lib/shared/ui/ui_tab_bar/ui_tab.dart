import 'package:flutter/material.dart';
import 'package:web_dex/mm2/mm2_sw.dart';

class UiTab extends StatelessWidget {
  const UiTab({
    Key? key,
    required this.text,
    required this.isSelected,
    this.onClick,
  }) : super(key: key);

  final String text;
  final bool isSelected;
  final Function? onClick;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      final textStyle = isRunningAsChromeExtension()
          ? Theme.of(context).textTheme.bodySmall
          : Theme.of(context).textTheme.bodyLarge;

      return Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(36.0),
        ),
        child: ElevatedButton(
          onPressed: onClick == null ? null : () => onClick!(),
          style: ElevatedButton.styleFrom(
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(36.0),
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: Center(
              child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          )),
        ),
      );
    }

    final enabled = onClick != null;

    final textStyle = isRunningAsChromeExtension()
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyLarge;

    return TextButton(
      clipBehavior: Clip.hardEdge,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        disabledForegroundColor: Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withOpacity(0.5),
      ),
      onPressed: enabled ? () => onClick!() : null,
      // onPressed: null,
      child: Center(
        child: Text(
          text,
          style: textStyle?.copyWith(
            color:
                enabled ? Theme.of(context).colorScheme.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }
}
