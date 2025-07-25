import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

const ColorSchemeExtension _colorSchemeExtension = ColorSchemeExtension(
  primary: Color(0xFF00D4FF), // Teal primary
  p50: Color(0xFF80EAD7), // Light teal
  p40: Color(0xFFB3F0E0), // Lighter teal
  p10: Color(0xFFE6F9F5), // Very light teal
  secondary: Color(0xFF00C3AA), // Teal secondary
  s70: Color.fromRGBO(125, 144, 161, 1),
  s50: Color.fromRGBO(162, 175, 187, 1),
  s40: Color.fromRGBO(181, 191, 201, 1),
  s30: Color.fromRGBO(199, 207, 214, 1),
  s20: Color.fromRGBO(218, 223, 228, 1),
  s10: Color.fromRGBO(236, 239, 241, 1),
  e10: Color.fromRGBO(250, 235, 240, 1),
  e20: Color.fromRGBO(246, 215, 225, 1),
  e50: Color.fromRGBO(233, 156, 179, 1),
  error: Color.fromRGBO(210, 57, 104, 1),
  g10: Color.fromRGBO(238, 249, 247, 1),
  g20: Color.fromRGBO(222, 242, 238, 1),
  green: Color.fromRGBO(88, 192, 171, 1),
  surf: Color.fromRGBO(255, 255, 255, 1),
  surfCont: Color.fromRGBO(255, 255, 255, 1),
  surfContHigh: Color.fromRGBO(245, 245, 245, 1),
  surfContHighest: Color.fromRGBO(235, 235, 235, 1),
  surfContLow: Color.fromRGBO(253, 253, 253, 1),
  surfContLowest: Color.fromRGBO(245, 245, 245, 1),
  orange: Color.fromRGBO(237, 170, 70, 1),
  yellow: Color.fromRGBO(230, 188, 65, 1),
  purple: Color.fromRGBO(123, 73, 221, 1),
);

final ColorScheme _colorScheme = theme.global.light.colorScheme.copyWith(
  primary: _colorSchemeExtension.primary,
  secondary: _colorSchemeExtension.secondary,
  error: _colorSchemeExtension.error,
);
final TextTheme _textTheme = theme.global.light.textTheme.copyWith();
final TextThemeExtension _textThemeExtension = TextThemeExtension(
  textColor: _colorSchemeExtension.secondary,
);
final ThemeData newThemeDataLight = theme.global.light.copyWith(
  colorScheme: _colorScheme,
  textTheme: _textTheme,
  inputDecorationTheme: theme.global.light.inputDecorationTheme.copyWith(
    hintStyle: _textThemeExtension.bodySBold
        .copyWith(color: _colorSchemeExtension.s50),
    labelStyle: _textThemeExtension.bodyXSBold
        .copyWith(color: _colorSchemeExtension.primary),
    errorStyle:
        _textThemeExtension.bodyS.copyWith(color: _colorSchemeExtension.error),
    enabledBorder: _outlineBorderLight(_colorSchemeExtension.secondary),
    disabledBorder: _outlineBorderLight(_colorSchemeExtension.secondary),
    focusedBorder: _outlineBorderLight(_colorSchemeExtension.primary),
    errorBorder: _outlineBorderLight(_colorSchemeExtension.error),
    fillColor: Colors.transparent,
    hoverColor: Colors.transparent,
  ),
  extensions: [_colorSchemeExtension, _textThemeExtension],
);

OutlineInputBorder _outlineBorderLight(Color accentColor) => OutlineInputBorder(
      borderSide: BorderSide(color: accentColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    );
