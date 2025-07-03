import 'package:flutter/material.dart';

import 'dark/theme_global_dark.dart';
import 'light/theme_global_light.dart';
import 'ultra_dark/theme_global_ultra_dark.dart';

class ThemeDataGlobal {
  final ThemeData light = themeGlobalLight;
  final ThemeData dark = themeGlobalDark;
  final ThemeData ultraDark = themeGlobalUltraDark;
}
