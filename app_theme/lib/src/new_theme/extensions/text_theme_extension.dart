import 'package:flutter/material.dart';

class TextThemeExtension extends ThemeExtension<TextThemeExtension> {
  TextThemeExtension({required Color textColor})
    : heading1 = TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      heading2 = TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyM = TextStyle(
        fontSize: 16,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      bodyMBold = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyS = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodySBold = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyXS = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyXSBold = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyXXS = TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyXXSBold = TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: textColor,
      );

  static TextThemeExtension of(BuildContext context) {
    final textTheme = Theme.of(context).extension<TextThemeExtension>();
    assert(textTheme != null, 'TextThemeExtension not found in context');
    return textTheme!;
  }

  final TextStyle heading1;
  final TextStyle heading2;
  final TextStyle bodyM;
  final TextStyle bodyMBold;
  final TextStyle bodyS;
  final TextStyle bodySBold;
  final TextStyle bodyXS;
  final TextStyle bodyXSBold;
  final TextStyle bodyXXS;
  final TextStyle bodyXXSBold;

  @override
  ThemeExtension<TextThemeExtension> copyWith() {
    return this;
  }

  @override
  ThemeExtension<TextThemeExtension> lerp(
    covariant ThemeExtension<TextThemeExtension>? other,
    double t,
  ) {
    return this;
  }
}
