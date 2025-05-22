import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class UiBorderButton extends StatelessWidget {
  const UiBorderButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.width = 300,
    this.height = 48,
    this.borderColor,
    this.borderWidth = 3,
    this.backgroundColor,
    this.prefix,
    this.suffix,
    this.icon,
    this.allowMultiline = false,
    this.fontWeight = FontWeight.w700,
    this.fontSize = 14,
    this.textColor,
    this.padding,
  });

  /// Constructor for a border button which inherits its size from the parent
  /// widget. See [UiPrimaryButton.flexible] for more details.
  ///
  /// The padding defaults to 16dp horizontal and 8dp vertical, following Material Design
  /// specifications. The button maintains the minimum dimensions of an outlined button
  /// (88dp width, 36dp height) unless explicitly overridden.
  const UiBorderButton.flexible({
    required this.text,
    required this.onPressed,
    super.key,
    this.borderColor,
    this.borderWidth = 3,
    this.backgroundColor,
    this.prefix,
    this.suffix,
    this.icon,
    this.allowMultiline = false,
    this.fontWeight = FontWeight.w700,
    this.fontSize = 14,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  })  : width = null,
        height = null;

  final String text;
  final double? width;
  final double? height;
  final Widget? prefix;
  final Widget? suffix;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderWidth;
  final Widget? icon;
  final void Function()? onPressed;
  final bool allowMultiline;
  final FontWeight fontWeight;
  final double fontSize;
  final Color? textColor;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Container(
        constraints: _buildConstraints(),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: borderColor ?? theme.custom.defaultBorderButtonBorder,
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  backgroundColor ?? theme.custom.defaultBorderButtonBackground,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(15),
                hoverColor: secondaryColor.withValues(alpha: 0.05),
                highlightColor: secondaryColor.withValues(alpha: 0.1),
                focusColor: secondaryColor.withValues(alpha: 0.2),
                splashColor: secondaryColor.withValues(alpha: 0.4),
                child: Padding(
                  padding: padding ?? const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Builder(
                    builder: (context) {
                      if (icon == null) {
                        return _ButtonText(
                          prefix: prefix,
                          text: text,
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                          textColor: textColor,
                          suffix: suffix,
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          icon,
                          Flexible(
                            child: _ButtonText(
                              prefix: prefix,
                              text: text,
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              textColor: textColor,
                              suffix: suffix,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxConstraints _buildConstraints() {
    // Material Design minimum dimensions for outlined buttons
    const double materialMinWidth = 88;
    const double materialMinHeight = 36;

    // For fixed sizes (backward compatibility)
    if (width != null || height != null) {
      if (width != null && height != null) {
        if (allowMultiline) {
          return BoxConstraints(minWidth: width!);
        }
        return BoxConstraints(minWidth: width!, minHeight: height!);
      } else if (width != null) {
        return BoxConstraints(minWidth: width!);
      } else if (height != null && !allowMultiline) {
        return BoxConstraints(minHeight: height!);
      }
    }

    // For flexible constructor - apply Material Design minimums
    // but allow growing to fit content
    if (width == null && height == null) {
      return BoxConstraints(
        minWidth: materialMinWidth,
        minHeight: materialMinHeight,
      );
    }

    // Fallback
    return const BoxConstraints();
  }
}

class _ButtonText extends StatelessWidget {
  const _ButtonText({
    required this.prefix,
    required this.text,
    required this.fontWeight,
    required this.fontSize,
    required this.suffix,
    this.textColor,
  });

  final Widget? prefix;
  final String text;
  final FontWeight fontWeight;
  final double fontSize;
  final Color? textColor;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final prefix = this.prefix;
    final suffix = this.suffix;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefix != null) ...[
          prefix,
          const SizedBox(width: 9),
        ],
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: fontSize,
                ),
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 9),
          suffix,
        ],
      ],
    );
  }
}
