import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/src/buttons/ui_base_button.dart';

class UiSecondaryButton extends StatefulWidget {
  const UiSecondaryButton({
    required this.onPressed,
    this.buttonKey,
    this.text = '',
    this.width = double.infinity,
    this.height = 48.0,
    this.borderColor,
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

  /// Constructor for a secondary button which inherits its size from the parent
  /// widget. See [UiPrimaryButton.flexible] for more details.
  ///
  /// The padding defaults to 16dp horizontal and 8dp vertical, following Material Design
  /// specifications. The button maintains the minimum dimensions of an outlined button
  /// (88dp width, 36dp height) unless explicitly overridden.
  const UiSecondaryButton.flexible({
    required this.onPressed,
    this.buttonKey,
    this.text = '',
    this.borderColor,
    this.textStyle,
    this.prefix,
    this.border,
    this.focusNode,
    this.shadowColor,
    this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius,
    super.key,
  })  : width = null,
        height = null;

  final String text;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final Color? borderColor;
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
  State<UiSecondaryButton> createState() => _UiSecondaryButtonState();
}

class _UiSecondaryButtonState extends State<UiSecondaryButton> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final shouldEnforceMinimumSize =
        widget.width == null && widget.height == null;
    final constraints = ButtonUtils.getButtonConstraints(
      width: widget.width,
      height: widget.height,
      shouldEnforceMinimumSize: shouldEnforceMinimumSize,
      expandToFillParent: widget.width == double.infinity,
    );

    final buttonWidget = ElevatedButton(
      focusNode: widget.focusNode,
      onFocusChange: (value) {
        setState(() => _hasFocus = value);
      },
      onPressed: widget.onPressed,
      key: widget.buttonKey,
      style: ElevatedButton.styleFrom(
        shape: _shape,
        side: BorderSide(
          color: _borderColor,
          width: 1,
        ),
        shadowColor: _shadowColor,
        elevation: 1,
        backgroundColor: Colors.transparent,
        foregroundColor: _borderColor,
        padding: widget.padding,
        minimumSize: shouldEnforceMinimumSize
            ? null
            : Size(
                constraints.minWidth > 0 ? constraints.minWidth : 0,
                constraints.minHeight > 0 ? constraints.minHeight : 0,
              ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: widget.child ??
          _ButtonContent(
            text: widget.text,
            textStyle: widget.textStyle,
            prefix: widget.prefix,
          ),
    );

    // Only apply size wrapper if needed
    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }

  Color get _borderColor {
    return widget.borderColor ?? Theme.of(context).colorScheme.secondary;
  }

  Color get _shadowColor {
    return _hasFocus
        ? widget.shadowColor ?? Theme.of(context).colorScheme.primary
        : Colors.transparent;
  }

  OutlinedBorder get _shape => RoundedRectangleBorder(
        borderRadius:
            BorderRadius.all(Radius.circular(widget.borderRadius ?? 18)),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null) prefix!,
        Text(text, style: textStyle ?? _defaultTextStyle(context)),
      ],
    );
  }

  TextStyle? _defaultTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Theme.of(context).colorScheme.secondary,
        );
  }
}
