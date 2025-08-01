import 'package:flutter/material.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final List<Color>? colors;
  final List<double>? stops;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;
  final bool showBorder;
  final double borderWidth;
  final double borderOpacity;
  final VoidCallback? onTap;

  const GradientContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.colors,
    this.stops,
    this.begin,
    this.end,
    this.showBorder = true,
    this.borderWidth = 1.0,
    this.borderOpacity = 0.3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default gradient colors based on theme
    final defaultColors = [
      theme.cardColor,
      theme.colorScheme.surface.withOpacity(0.95),
    ];

    final defaultStops = [0.0, 0.6, 1.0];

    final container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin ?? Alignment.topRight,
          end: end ?? Alignment.bottomLeft,
          colors: colors ?? defaultColors,
          stops: stops ?? defaultStops,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: showBorder
            ? Border.all(
                color: theme.dividerColor,
                width: borderWidth,
              )
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: container,
      );
    }

    return container;
  }
}
