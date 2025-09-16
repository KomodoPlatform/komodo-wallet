import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/src/buttons/ui_base_button.dart';

class UiPrimaryButton extends StatefulWidget {
  const UiPrimaryButton({
    required this.onPressed,
    this.buttonKey,
    this.text = '',
    this.width = double.infinity,
    this.height = 48.0,
    this.backgroundColor,
    this.textStyle,
    this.prefix,
    this.border,
    this.focusNode,
    this.shadowColor,
    this.child,
    this.padding,
    this.borderRadius,
    super.key,
  });

  final String text;
  final TextStyle? textStyle;
  final double width;
  final double height;
  final Color? backgroundColor;
  final Widget? prefix;
  final Key? buttonKey;
  final BoxBorder? border;
  final void Function()? onPressed;
  final FocusNode? focusNode;
  final Color? shadowColor;
  final Widget? child;
  final EdgeInsets? padding;
  final double? borderRadius;

  @override
  State<UiPrimaryButton> createState() => _UiPrimaryButtonState();
}

class _UiPrimaryButtonState extends State<UiPrimaryButton> {
  bool _hasFocus = false;
  @override
  Widget build(BuildContext context) {
    return UIBaseButton(
      isEnabled: widget.onPressed != null,
      width: widget.width,
      height: widget.height,
      border: widget.border,
      child: ElevatedButton(
        focusNode: widget.focusNode,
        onFocusChange: (value) {
          setState(() {
            _hasFocus = value;
          });
        },
        onPressed: widget.onPressed ?? () {},
        key: widget.buttonKey,
        style: ElevatedButton.styleFrom(
          shape: _shape,
          shadowColor: _shadowColor,
          elevation: 1,
          backgroundColor: _backgroundColor,
          foregroundColor: _foregroundColor,
          padding: widget.padding,
        ),
        child: DefaultTextStyle(
          style: _defaultTextStyle(context) ??
              widget.textStyle ??
              const TextStyle(),
          child: widget.child ??
              _ButtonContent(
                text: widget.text,
                textStyle: widget.textStyle,
                prefix: widget.prefix,
              ),
        ),
      ),
    );
  }

  Color get _backgroundColor {
    // Always use the theme's primary color for both background and text
    return widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
  }

  Color get _shadowColor {
    return _hasFocus
        ? widget.shadowColor ?? Theme.of(context).colorScheme.primary
        : Colors.transparent;
  }

  Color get _foregroundColor {
    return ThemeData.estimateBrightnessForColor(_backgroundColor) ==
            Brightness.dark
        ? theme.global.light.colorScheme.onSurface
        : Theme.of(context).colorScheme.secondary;
  }

  OutlinedBorder get _shape => RoundedRectangleBorder(
        borderRadius:
            BorderRadius.all(Radius.circular(widget.borderRadius ?? 18)),
      );
}

TextStyle? _defaultTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: theme.custom.defaultGradientButtonTextColor,
      );
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.text,
    required this.textStyle,
    required this.prefix,
  });

  final String text;
  final TextStyle? textStyle;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefix != null) prefix!,
        Text(text, style: textStyle ?? _defaultTextStyle(context)),
      ],
    );
  }
}
