import 'package:flutter/material.dart';

class DexThemeSwitcher extends StatefulWidget {
  const DexThemeSwitcher({
    super.key,
    required this.isDarkTheme,
    required this.onThemeModeChanged,
    required this.lightThemeTitle,
    required this.darkThemeTitle,
    required this.buttonKeyValue,
    required this.switcherStyle,
  });
  final String lightThemeTitle;
  final String darkThemeTitle;
  final bool isDarkTheme;
  final void Function(ThemeMode) onThemeModeChanged;
  final String buttonKeyValue;
  final DexThemeSwitcherStyle switcherStyle;

  static const borderRadius = BorderRadius.all(Radius.circular(20));

  @override
  State<DexThemeSwitcher> createState() => _DexThemeSwitcherState();
}

class _DexThemeSwitcherState extends State<DexThemeSwitcher> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        DexThemeSwitcherStyle style = widget.switcherStyle;
        final rightConstrain =
            constrains.maxWidth - style.widthOfThumb - 2 * style.padding;

        return InkWell(
          hoverColor: Colors.transparent,
          onHover: (value) => setState(() => _isHovered = value),
          key: Key(widget.buttonKeyValue),
          borderRadius: DexThemeSwitcher.borderRadius,
          onTap: () {
            widget.onThemeModeChanged(
              widget.isDarkTheme ? ThemeMode.light : ThemeMode.dark,
            );
          },
          child: AnimatedContainer(
            duration: style.bgAnimationDuration,
            width: 208,
            height: style.height,
            padding: EdgeInsets.all(style.padding),
            decoration: BoxDecoration(
              color: style.switcherBgColor,
              borderRadius: DexThemeSwitcher.borderRadius,
            ),
            curve: style.curve,
            child: Stack(
              children: [
                if (constrains.maxWidth > 140)
                  _Text(
                    isDarkTheme: widget.isDarkTheme,
                    lightThemeTitle: widget.lightThemeTitle,
                    darkThemeTitle: widget.darkThemeTitle,
                    style: style,
                  ),
                AnimatedPositioned(
                  left: widget.isDarkTheme ? rightConstrain : 0,
                  duration: style.mainAnimationDuration,
                  curve: style.curve,
                  child: _Thumb(
                    isDarkTheme: widget.isDarkTheme,
                    style: style,
                    isHovered: _isHovered,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({
    required bool isDarkTheme,
    required this.lightThemeTitle,
    required this.darkThemeTitle,
    required this.style,
  }) : _isDarkTheme = isDarkTheme;

  final bool _isDarkTheme;
  final String lightThemeTitle;
  final String darkThemeTitle;
  final DexThemeSwitcherStyle style;

  static const String _textKey1 = 'animated-switcher-text-1';
  static const String _textKey2 = 'animated-switcher-text-2';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: style.height),
        AnimatedSwitcher(
          duration: style.bgAnimationDuration,
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Padding(
            key: Key(_isDarkTheme ? _textKey1 : _textKey2),
            padding: EdgeInsets.only(
              left: _isDarkTheme
                  ? style.padding
                  : style.widthOfThumb + style.padding,
              right: _isDarkTheme
                  ? style.widthOfThumb + style.padding
                  : style.padding,
            ),
            child: Text(
              _isDarkTheme ? darkThemeTitle : lightThemeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: style.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final bool isDarkTheme;
  final DexThemeSwitcherStyle style;
  final bool isHovered;

  const _Thumb({
    required this.isDarkTheme,
    required this.style,
    required this.isHovered,
  });

  static const _iconKey1 = 'animated-switcher-icon-1';
  static const _iconKey2 = 'animated-switcher-icon-2';

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: style.widthOfThumb,
      width: style.widthOfThumb,
      alignment: Alignment.center,
      duration: style.mainAnimationDuration,
      curve: style.curve,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: style.thumbBgColor.withValues(alpha: isHovered ? 0.6 : 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: AnimatedScale(
        duration: style.bgAnimationDuration,
        scale: isHovered ? 1.1 : 1,
        curve: style.curve,
        child: AnimatedSwitcher(
          duration: style.bgAnimationDuration,
          switchInCurve: style.curve,
          switchOutCurve: style.curve,
          child: Icon(
            key: Key(isDarkTheme ? _iconKey1 : _iconKey2),
            isDarkTheme ? Icons.dark_mode_sharp : Icons.light_mode_sharp,
            color: style.textColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class DexThemeSwitcherStyle {
  final Cubic curve;
  final double padding;
  final double widthOfThumb;
  final double height;
  final Duration mainAnimationDuration;
  final Duration bgAnimationDuration;
  final Color textColor;
  final Color thumbBgColor;
  final Color switcherBgColor;

  DexThemeSwitcherStyle({
    this.curve = Curves.ease,
    this.padding = 4,
    this.widthOfThumb = 48,
    this.height = 56,
    this.mainAnimationDuration = const Duration(milliseconds: 300),
    this.bgAnimationDuration = const Duration(milliseconds: 100),
    required this.textColor,
    required this.thumbBgColor,
    required this.switcherBgColor,
  });

  DexThemeSwitcherStyle copyWith({
    Cubic? curve,
    double? padding,
    double? widthOfThumb,
    double? height,
    Duration? mainAnimationDuration,
    Duration? bgAnimationDuration,
    Color? textColor,
    Color? thumbBgColor,
    Color? switcherBgColor,
  }) {
    return DexThemeSwitcherStyle(
      curve: curve ?? this.curve,
      padding: padding ?? this.padding,
      widthOfThumb: widthOfThumb ?? this.widthOfThumb,
      height: height ?? this.height,
      mainAnimationDuration:
          mainAnimationDuration ?? this.mainAnimationDuration,
      bgAnimationDuration: bgAnimationDuration ?? this.bgAnimationDuration,
      textColor: textColor ?? this.textColor,
      thumbBgColor: thumbBgColor ?? this.thumbBgColor,
      switcherBgColor: switcherBgColor ?? this.switcherBgColor,
    );
  }
}
