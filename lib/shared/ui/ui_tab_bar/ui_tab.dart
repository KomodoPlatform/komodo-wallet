import 'package:flutter/material.dart';

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
            style: Theme.of(context).primaryTextTheme.bodyMedium?.copyWith(
                  // Use the same color scheme as in `dex_text_button.dart`
                  // for now
                  color: isSelected
                      ? Theme.of(context).primaryTextTheme.labelLarge?.color
                      : Theme.of(context).textTheme.labelLarge?.color,
                ),
          ),
        ),
      ),
    );
  }
}
