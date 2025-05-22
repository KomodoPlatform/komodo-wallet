import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/src/buttons/ui_base_button.dart';

class UiPrimaryButton extends StatefulWidget {
  /// Creates a primary button with the given properties.
  ///
  /// NB! Prefer using the [UiPrimaryButton.flexible] constructor. The [width]
  /// and [height] parameters will be deprecated in the future and the button
  /// will have the same behavior as the [UiPrimaryButton.flexible] constructor.
  @Deprecated('Use UiPrimaryButton.flexible instead.')
  const UiPrimaryButton({
    this.onPressed,
    this.text = '',
    this.width = double.infinity,
    this.height = 48.0,
    this.backgroundColor,
    this.textStyle,
    this.prefix,
    this.prefixPadding,
    this.border,
    this.focusNode,
    this.shadowColor,
    this.child,
    this.padding,
    this.borderRadius,
    this.optimisticEnabledDuration,
    this.onOptimisticEnabledTimeout,
    super.key,
  });

  /// Constructor for a primary button which inherits its size from the parent
  /// widget.
  ///
  /// By default, the button will take up the minimum width required to fit its
  /// content and use the minimum height needed. If you want it to take up the
  /// full width of its parent, wrap it in a [SizedBox] or a [Container] with
  /// `width: double.infinity`.
  ///
  /// The padding defaults to 16dp horizontal and 8dp vertical, following Material Design
  /// specifications. The button maintains the minimum dimensions of a contained button
  /// (88dp width, 36dp height) unless explicitly overridden.
  ///
  /// For displaying text, use the [child] parameter with a [Text] widget. For example:
  /// ```dart
  /// UiPrimaryButton.flexible(
  ///   onPressed: () {},
  ///   child: Text('Button Text'),
  /// )
  /// ```
  const UiPrimaryButton.flexible({
    this.onPressed,
    super.key,
    // TODO: Remove this in the future in favor of using the `child` parameter
    // to better follow the Flutter conventions.
    this.text = '',
    this.backgroundColor,
    this.textStyle,
    this.prefix,
    this.prefixPadding = const EdgeInsets.only(right: 12),
    this.border,
    this.focusNode,
    this.shadowColor,
    this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius,
    this.optimisticEnabledDuration,
    this.onOptimisticEnabledTimeout,
  })  : width = null,
        height = null;

  /// The text to display on the button
  final String text;

  /// The style to apply to the button's text
  final TextStyle? textStyle;

  /// The width of the button. If null, the button will size itself to its content
  final double? width;

  /// The height of the button. If null, the button will size itself to its content
  final double? height;

  /// The background color of the button
  final Color? backgroundColor;

  /// A widget to display before the button's text
  final Widget? prefix;

  /// The padding to apply to the prefix widget
  final EdgeInsets? prefixPadding;

  /// The border to apply to the button
  final BoxBorder? border;

  /// Called when the button is tapped
  final void Function()? onPressed;

  /// The focus node to use for the button
  final FocusNode? focusNode;

  /// The color of the button's shadow when focused
  final Color? shadowColor;

  /// A custom child widget to display instead of text
  final Widget? child;

  /// The padding to apply to the button's content
  final EdgeInsets? padding;

  /// The border radius of the button
  final double? borderRadius;

  /// Duration for which a disabled button should appear enabled and show a loading
  /// state if tapped. If [onPressed] becomes non-null during this period, it will
  /// be called immediately.
  ///
  /// This creates an "optimistic UI" where buttons appear ready for interaction even
  /// if they are technically disabled, improving perceived performance when the app
  /// is waiting for some condition that will enable the button.
  final Duration? optimisticEnabledDuration;

  /// Called when the [optimisticEnabledDuration] expires after the user taps
  /// the button and if the button is still not enabled ([onPressed] is still null).
  final VoidCallback? onOptimisticEnabledTimeout;

  @override
  State<UiPrimaryButton> createState() => _UiPrimaryButtonState();
}

class _UiPrimaryButtonState extends State<UiPrimaryButton> {
  bool _hasFocus = false;
  bool _isLoading = false;
  Timer? _loadingTimer;

  @override
  void didUpdateWidget(UiPrimaryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the button becomes enabled while in loading state, immediately execute onPressed
    if (widget.onPressed != null && oldWidget.onPressed == null && _isLoading) {
      _loadingTimer?.cancel();
      setState(() => _isLoading = false);
      widget.onPressed!();
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _handlePress() {
    // If onPressed is available, execute it and clear any loading state
    if (widget.onPressed != null) {
      _loadingTimer?.cancel();
      if (_isLoading) {
        setState(() => _isLoading = false);
      }
      widget.onPressed!();
      return;
    }

    // Only show loading state if optimisticEnabledDuration is specified and not already loading
    if (!_isLoading && widget.optimisticEnabledDuration != null) {
      setState(() => _isLoading = true);
      _loadingTimer?.cancel();
      _loadingTimer = Timer(widget.optimisticEnabledDuration!, () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        widget.onOptimisticEnabledTimeout?.call();
      });
    }
  }

  /// Determines if the button should appear enabled, even if it's technically disabled
  bool get _shouldAppearEnabled {
    return widget.onPressed != null ||
        (widget.optimisticEnabledDuration != null) ||
        _isLoading;
  }

  Color get _backgroundColor {
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

    // This is the key change - we determine if the button should appear enabled
    // based on our new logic that includes optimisticEnabledDuration
    final shouldAppearEnabled = _shouldAppearEnabled;

    // Create the base button widget
    final button = ElevatedButton(
      focusNode: widget.focusNode,
      onFocusChange: (value) {
        setState(() => _hasFocus = value);
      },
      // Always allow the button to be pressed if it should appear enabled
      onPressed: shouldAppearEnabled ? _handlePress : null,
      style: ElevatedButton.styleFrom(
        shape: _shape,
        shadowColor: _shadowColor,
        elevation: 1,
        backgroundColor: _backgroundColor,
        foregroundColor: _foregroundColor,
        padding: widget.padding,
        minimumSize: shouldEnforceMinimumSize
            ? null
            : Size(
                constraints.minWidth > 0 ? constraints.minWidth : 0,
                constraints.minHeight > 0 ? constraints.minHeight : 0,
              ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: widget.border != null
            ? BorderSide(
                width: 1,
                color: widget.border is Border
                    ? (widget.border as Border).top.color
                    : Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
      child: _isLoading
          ? _buildLoadingIndicator()
          : widget.child ??
              _ButtonContent(
                text: widget.text,
                textStyle: widget.textStyle,
                prefix: widget.prefix,
                prefixPadding: widget.prefixPadding,
              ),
    );

    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: button,
      );
    }

    return button;
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.text,
    required this.textStyle,
    required this.prefix,
    this.prefixPadding,
  });

  final String text;
  final TextStyle? textStyle;
  final Widget? prefix;
  final EdgeInsets? prefixPadding;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null)
          Container(
            padding: prefixPadding,
            child: prefix!,
          ),
        Text(text, style: textStyle ?? _defaultTextStyle(context)),
      ],
    );
  }

  TextStyle? _defaultTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: theme.custom.defaultGradientButtonTextColor,
        );
  }
}
