import 'package:flutter/material.dart';

class ColorSchemeExtension extends ThemeExtension<ColorSchemeExtension> {
  const ColorSchemeExtension({
    required this.primary,
    required this.p50,
    required this.p40,
    required this.p10,
    required this.secondary,
    required this.s70,
    required this.s50,
    required this.s40,
    required this.s30,
    required this.s20,
    required this.s10,
    required this.surf,
    required this.surfContHighest,
    required this.surfContHigh,
    required this.surfCont,
    required this.surfContLow,
    required this.surfContLowest,
    required this.error,
    required this.e50,
    required this.e20,
    required this.e10,
    required this.green,
    required this.g20,
    required this.g10,
    required this.orange,
    required this.yellow,
    required this.purple,
  });
  final Color primary;
  final Color p50;
  final Color p40;
  final Color p10;
  final Color secondary;
  final Color s70;
  final Color s50;
  final Color s40;
  final Color s30;
  final Color s20;
  final Color s10;
  final Color surf;
  final Color surfContHighest;
  final Color surfContHigh;
  final Color surfCont;
  final Color surfContLow;
  final Color surfContLowest;
  final Color error;
  final Color e50;
  final Color e20;
  final Color e10;
  final Color green;
  final Color g20;
  final Color g10;
  final Color orange;
  final Color yellow;
  final Color purple;

  @override
  ThemeExtension<ColorSchemeExtension> copyWith() {
    return this;
  }

  @override
  ThemeExtension<ColorSchemeExtension> lerp(
      covariant ThemeExtension<ColorSchemeExtension>? other, double t) {
    return this;
  }
}
