import 'package:flutter/material.dart';

/// A button that displays multiple children separated by dividers.
///
/// This widget maintains the same functionality as the original DividedButton
/// while adding more customization options and better theme integration.
///
/// There may be breaking changes in the near future that enhance
/// re-usability and customization, but the initial version will be focused on
/// migrating from the Komodo Wallet app to the new SDK repository.
///
/// E.g.:
/// - Currently tied to FilledButton styling
/// - Uses specific theme properties from segmentedButtonTheme
///
/// Could be more flexible with:
/// - Custom layout system beyond just Row
/// - Container styling beyond button styles
/// - Support for different divider patterns/layouts
/// - Better touch target sizing
/// - More flexible children spacing
class DividedButton extends StatelessWidget {
  /// A button that displays multiple children separated by dividers.
  ///
  /// This widget maintains the same functionality as the original
  /// DividedButton while adding more customization options and better theme
  /// integration.
  const DividedButton({
    required this.children,
    this.childPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.dividerColor,
    this.dividerThickness = 1,
    this.dividerIndent = 2,
    this.dividerEndIndent = 2,
    this.dividerHeight = 32,
    this.backgroundColor,
    this.shape,
    this.onPressed,
    super.key,
  });

  /// Widgets to display in each section
  final List<Widget> children;

  /// Padding around each child
  final EdgeInsetsGeometry? childPadding;

  /// Color of the dividers (defaults to theme's divider color)
  final Color? dividerColor;

  /// Thickness of the dividers
  final double dividerThickness;

  /// Top indent of dividers
  final double dividerIndent;

  /// Bottom indent of dividers
  final double dividerEndIndent;

  /// Height of the dividers
  final double dividerHeight;

  /// Background color (defaults to theme's surface color)
  final Color? backgroundColor;

  /// Shape of the button (defaults to rounded rectangle)
  final OutlinedBorder? shape;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segmentedStyle = theme.segmentedButtonTheme.style;

    return FilledButton(
      style: (segmentedStyle ?? const ButtonStyle()).copyWith(
        shape: WidgetStatePropertyAll(
          shape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        textStyle: WidgetStatePropertyAll(theme.textTheme.labelMedium),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(
          backgroundColor ??
              segmentedStyle?.backgroundColor?.resolve({WidgetState.focused}) ??
              theme.colorScheme.surface,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (childPadding != null)
              Padding(padding: childPadding!, child: children[i])
            else
              children[i],
            if (i < children.length - 1)
              SizedBox(
                height: dividerHeight,
                child: VerticalDivider(
                  width: dividerThickness,
                  thickness: dividerThickness,
                  indent: dividerIndent,
                  endIndent: dividerEndIndent,
                  color: dividerColor,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
