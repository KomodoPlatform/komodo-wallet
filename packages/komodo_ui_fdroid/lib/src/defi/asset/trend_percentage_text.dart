import 'package:flutter/material.dart';

/// A widget that displays a percentage trend with an indicator icon.
///
/// Enhanced version with animation support for smooth value transitions.
/// Animates value changes, percentage changes, and color transitions.
///
/// There may be breaking changes in the near future that enhance
/// re-usability and customization, but the initial version will be focused on
/// migrating from the Komodo Wallet app to the new SDK repository.
///
/// E.g.:
/// - Locked into using percentage prop name
/// - Fixed icon choices and behaviors
///
/// Could be enhanced with:
/// - More general value representation
/// - Custom formatters
/// - Support for different trend indicators
/// - Multi-period comparisons
class TrendPercentageText extends StatefulWidget {
  /// A widget that displays a percentage trend with an indicator icon.
  ///
  /// Enhanced version with animation support and more customization
  /// options while maintaining backwards compatibility.
  const TrendPercentageText({
    this.value,
    this.percentage,
    this.showIcon = true,
    this.iconSize = 18,
    this.contentSpacing = 1,
    this.spacing = 2,
    this.valuePrecision = 2,
    this.percentagePrecision = 2,
    this.upIcon = Icons.north,
    this.downIcon = Icons.south,
    this.neutralIcon = Icons.trending_flat,
    this.upColor,
    this.downColor,
    this.neutralColor,
    this.textStyle,
    this.prefix,
    this.suffix,
    this.noValueText = '-',
    this.showPercentageInParentheses = true,
    this.showPlusSign = true,
    this.valueFormatter,
    this.percentageFormatter,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeInOut,
    this.enableAnimation = true,
    this.animateIcon = true,
    this.animateColor = true,
    super.key,
  });

  /// The actual value to display (optional)
  final double? value;

  /// The percentage value to display
  /// If null, will display [noValueText] and use neutral styling
  final double? percentage;

  /// Text to display when percentage is null
  final String noValueText;

  /// Whether to show the trend icon
  final bool showIcon;

  /// Size of the trend icon
  final double iconSize;

  /// Spacing between icon and text
  final double spacing;

  /// Spacing between contents and prefix/suffix
  final double contentSpacing;

  /// Number of decimal places to show for the value
  final int valuePrecision;

  /// Number of decimal places to show for the percentage
  final int percentagePrecision;

  /// Icon for upward trend
  final IconData upIcon;

  /// Icon for downward trend
  final IconData downIcon;

  /// Icon for neutral/no trend
  final IconData neutralIcon;

  /// Color for positive trends
  final Color? upColor;

  /// Color for negative trends
  final Color? downColor;

  /// Color for neutral/no trend
  final Color? neutralColor;

  /// Optional text style (falls back to theme's labelLarge)
  final TextStyle? textStyle;

  /// Optional prefix widget to display before the trend icon and text
  ///
  /// Typically a `Text` widget. The trend text style will automatically be
  /// applied to the prefix widget.
  final Widget? prefix;

  /// Optional suffix widget to display after the text
  ///
  /// Typically a `Text` widget. The trend text style will automatically be
  /// applied to the suffix widget.
  final Widget? suffix;

  /// Whether to show percentage in parentheses when both value and percentage
  /// are displayed
  final bool showPercentageInParentheses;

  /// Whether to show plus sign for positive percentages
  final bool showPlusSign;

  /// Custom formatter for the value
  final String Function(double value)? valueFormatter;

  /// Custom formatter for the percentage
  final String Function(double percentage)? percentageFormatter;

  /// Duration of the animation when values change
  final Duration animationDuration;

  /// Curve to use for the animation
  final Curve animationCurve;

  /// Whether to enable animations
  final bool enableAnimation;

  /// Whether to animate icon changes
  final bool animateIcon;

  /// Whether to animate color transitions
  final bool animateColor;

  @override
  State<TrendPercentageText> createState() => _TrendPercentageTextState();
}

class _TrendPercentageTextState extends State<TrendPercentageText>
    with SingleTickerProviderStateMixin {
  // Cached values to prevent recalculation
  late bool _isPositive;
  late bool _isNeutral;
  late bool _hasValue;
  late IconData _currentIcon;
  late Color _targetColor;

  // Theme cache
  ThemeData? _cachedTheme;

  @override
  void initState() {
    super.initState();
    _updateCachedValues();
  }

  void _updateCachedValues() {
    _isPositive = widget.percentage != null && widget.percentage! > 0;
    _isNeutral = widget.percentage == null || widget.percentage == 0;
    _hasValue = widget.value != null || widget.percentage != null;
    _currentIcon =
        _isPositive
            ? widget.upIcon
            : _isNeutral
            ? widget.neutralIcon
            : widget.downIcon;
  }

  void _updateTargetColor(ThemeData theme) {
    if (_cachedTheme != theme) {
      _cachedTheme = theme;
    }
    _targetColor =
        _isPositive
            ? (widget.upColor ?? Colors.green)
            : _isNeutral
            ? (widget.neutralColor ?? theme.disabledColor)
            : (widget.downColor ?? theme.colorScheme.error);
  }

  @override
  void didUpdateWidget(TrendPercentageText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update if percentage actually changed
    if (oldWidget.percentage != widget.percentage ||
        oldWidget.upIcon != widget.upIcon ||
        oldWidget.downIcon != widget.downIcon ||
        oldWidget.neutralIcon != widget.neutralIcon) {
      _updateCachedValues();
    }
  }

  String _formatValue(double val) {
    if (widget.valueFormatter != null) {
      return widget.valueFormatter!(val);
    }
    return val.toStringAsFixed(widget.valuePrecision).replaceAll('.', ',');
  }

  String _formatPercentage(double pct) {
    if (widget.percentageFormatter != null) {
      return widget.percentageFormatter!(pct);
    }

    final formatted = pct.toStringAsFixed(widget.percentagePrecision);
    final sign = (widget.showPlusSign && pct > 0) ? '+' : '';
    return '$sign$formatted%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _updateTargetColor(theme);

    final defaultTextStyle =
        theme.textTheme.labelLarge ?? const TextStyle(fontSize: 18);

    // Build the main content
    return _AnimatedColorWrapper(
      targetColor: _targetColor,
      duration:
          widget.animateColor && widget.enableAnimation
              ? widget.animationDuration
              : Duration.zero,
      curve: widget.animationCurve,
      builder: (context, color) {
        final baseStyle = (widget.textStyle ?? defaultTextStyle).copyWith(
          color: color,
        );

        // Different font weights for value and percentage
        final valueStyle = baseStyle.copyWith(fontWeight: FontWeight.w600);
        final percentageStyle = baseStyle.copyWith(
          fontWeight: FontWeight.normal,
        );

        return _TrendContent(
          showIcon: widget.showIcon,
          icon: _currentIcon,
          iconSize: widget.iconSize,
          iconColor: color,
          spacing: widget.spacing,
          contentSpacing: widget.contentSpacing,
          hasValue: _hasValue,
          noValueText: widget.noValueText,
          value: widget.value,
          percentage: widget.percentage,
          valueStyle: valueStyle,
          percentageStyle: percentageStyle,
          baseStyle: baseStyle,
          prefix: widget.prefix,
          suffix: widget.suffix,
          showPercentageInParentheses: widget.showPercentageInParentheses,
          formatValue: _formatValue,
          formatPercentage: _formatPercentage,
          enableAnimation: widget.enableAnimation,
          animateIcon: widget.animateIcon,
          animationDuration: widget.animationDuration,
          animationCurve: widget.animationCurve,
        );
      },
    );
  }
}

/// Optimized content widget that minimizes rebuilds
class _TrendContent extends StatelessWidget {
  const _TrendContent({
    required this.showIcon,
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.spacing,
    required this.contentSpacing,
    required this.hasValue,
    required this.noValueText,
    required this.value,
    required this.percentage,
    required this.valueStyle,
    required this.percentageStyle,
    required this.baseStyle,
    required this.prefix,
    required this.suffix,
    required this.showPercentageInParentheses,
    required this.formatValue,
    required this.formatPercentage,
    required this.enableAnimation,
    required this.animateIcon,
    required this.animationDuration,
    required this.animationCurve,
  });

  final bool showIcon;
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final double spacing;
  final double contentSpacing;
  final bool hasValue;
  final String noValueText;
  final double? value;
  final double? percentage;
  final TextStyle valueStyle;
  final TextStyle percentageStyle;
  final TextStyle baseStyle;
  final Widget? prefix;
  final Widget? suffix;
  final bool showPercentageInParentheses;
  final String Function(double) formatValue;
  final String Function(double) formatPercentage;
  final bool enableAnimation;
  final bool animateIcon;
  final Duration animationDuration;
  final Curve animationCurve;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          _AnimatedIcon(
            icon: icon,
            color: iconColor,
            size: iconSize,
            enableAnimation: enableAnimation && animateIcon,
            duration: animationDuration,
            curve: animationCurve,
          ),
          SizedBox(width: spacing),
        ],
        if (prefix != null) ...[
          DefaultTextStyle(style: valueStyle, child: prefix!),
          SizedBox(width: contentSpacing),
        ],
        // Build the text with different weights
        if (!hasValue)
          Text(noValueText, style: valueStyle)
        else
          _ValueDisplay(
            value: value,
            percentage: percentage,
            valueStyle: valueStyle,
            percentageStyle: percentageStyle,
            showPercentageInParentheses: showPercentageInParentheses,
            formatValue: formatValue,
            formatPercentage: formatPercentage,
            enableAnimation: enableAnimation,
            animationDuration: animationDuration,
            animationCurve: animationCurve,
          ),
        if (suffix != null) ...[
          SizedBox(width: contentSpacing),
          DefaultTextStyle(style: baseStyle, child: suffix!),
        ],
      ],
    );
  }
}

/// Separate widget for value display to optimize rebuilds
class _ValueDisplay extends StatelessWidget {
  const _ValueDisplay({
    required this.value,
    required this.percentage,
    required this.valueStyle,
    required this.percentageStyle,
    required this.showPercentageInParentheses,
    required this.formatValue,
    required this.formatPercentage,
    required this.enableAnimation,
    required this.animationDuration,
    required this.animationCurve,
  });

  final double? value;
  final double? percentage;
  final TextStyle valueStyle;
  final TextStyle percentageStyle;
  final bool showPercentageInParentheses;
  final String Function(double) formatValue;
  final String Function(double) formatPercentage;
  final bool enableAnimation;
  final Duration animationDuration;
  final Curve animationCurve;

  // Const spacing widget to prevent recreations
  static const _spacing = SizedBox(width: 3);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null)
          _AnimatedNumber(
            value: value!,
            formatter: formatValue,
            style: valueStyle,
            duration: enableAnimation ? animationDuration : Duration.zero,
            curve: animationCurve,
          ),
        if (value != null && percentage != null) _spacing,
        if (percentage != null)
          _AnimatedNumber(
            value: percentage!,
            formatter: (pct) {
              final formatted = formatPercentage(pct);
              return value != null && showPercentageInParentheses
                  ? '($formatted)'
                  : formatted;
            },
            style: percentageStyle,
            duration: enableAnimation ? animationDuration : Duration.zero,
            curve: animationCurve,
          ),
      ],
    );
  }
}

/// Optimized animated icon widget
class _AnimatedIcon extends StatefulWidget {
  const _AnimatedIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.enableAnimation,
    required this.duration,
    required this.curve,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool enableAnimation;
  final Duration duration;
  final Curve curve;

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late IconData _previousIcon;
  late IconData _currentIcon;

  @override
  void initState() {
    super.initState();
    _currentIcon = widget.icon;
    _previousIcon = widget.icon;

    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _previousIcon = _currentIcon;
      });
    }
  }

  @override
  void didUpdateWidget(_AnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.icon != widget.icon) {
      _currentIcon = widget.icon;
      if (widget.enableAnimation) {
        _controller.reset();
        _controller.forward();
      } else {
        _previousIcon = _currentIcon;
      }
    }

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableAnimation || _previousIcon == _currentIcon) {
      return Icon(_currentIcon, color: widget.color, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animValue = _animation.value.clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1 - animValue).clamp(0.0, 1.0),
              child: Icon(
                _previousIcon,
                color: widget.color,
                size: widget.size,
              ),
            ),
            Opacity(
              opacity: animValue,
              child: Icon(_currentIcon, color: widget.color, size: widget.size),
            ),
          ],
        );
      },
    );
  }
}

/// Optimized animated number widget with proper tween reuse
class _AnimatedNumber extends StatefulWidget {
  const _AnimatedNumber({
    required this.value,
    required this.formatter,
    required this.style,
    required this.duration,
    required this.curve,
  });

  final double value;
  final String Function(double) formatter;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  @override
  State<_AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<_AnimatedNumber> {
  late Tween<double> _tween;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _tween = Tween(begin: widget.value, end: widget.value);
  }

  @override
  void didUpdateWidget(_AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _tween = Tween(begin: _currentValue, end: widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: _tween,
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, child) {
        _currentValue = value;
        return Text(widget.formatter(value), style: widget.style);
      },
    );
  }
}

/// Optimized color animation wrapper
class _AnimatedColorWrapper extends StatefulWidget {
  const _AnimatedColorWrapper({
    required this.targetColor,
    required this.duration,
    required this.curve,
    required this.builder,
  });

  final Color targetColor;
  final Duration duration;
  final Curve curve;
  final Widget Function(BuildContext, Color) builder;

  @override
  State<_AnimatedColorWrapper> createState() => _AnimatedColorWrapperState();
}

class _AnimatedColorWrapperState extends State<_AnimatedColorWrapper> {
  late ColorTween _colorTween;
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.targetColor;
    _colorTween = ColorTween(
      begin: widget.targetColor,
      end: widget.targetColor,
    );
  }

  @override
  void didUpdateWidget(_AnimatedColorWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetColor != widget.targetColor) {
      _colorTween = ColorTween(begin: _currentColor, end: widget.targetColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: _colorTween,
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, color, child) {
        _currentColor = color ?? widget.targetColor;
        return widget.builder(context, _currentColor);
      },
    );
  }
}
