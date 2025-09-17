import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class UiSimpleBorderButton extends StatelessWidget {
  const UiSimpleBorderButton({
    Key? key,
    this.onPressed,
    this.inProgress = false,
    this.style,
    this.padding,
    required this.child,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget child;
  final bool inProgress;
  final TextStyle? style;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final Color? color = Theme.of(context).textTheme.bodyMedium?.color;
    final TextStyle effectiveStyle = TextStyle(
      fontSize: 12,
      color: color,
    ).merge(style);
    final EdgeInsets effectivePadding =
        padding ?? const EdgeInsets.fromLTRB(15, 1, 15, 1);
    const double borderRadius = 16;

    return Stack(
      children: [
        Opacity(
          opacity: inProgress ? 0 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: theme.custom.specificButtonBackgroundColor,
              border: Border.all(
                width: 1,
                color: theme.custom.specificButtonBorderColor,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: effectivePadding,
                  child: DefaultTextStyle(style: effectiveStyle, child: child),
                ),
              ),
            ),
          ),
        ),
        if (inProgress)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: UiSpinner(
                width: effectiveStyle.fontSize! * 1.2,
                height: effectiveStyle.fontSize! * 1.2,
                strokeWidth: effectiveStyle.fontSize! * 0.12,
              ),
            ),
          ),
      ],
    );
  }
}
