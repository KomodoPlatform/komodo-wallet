import 'package:flutter/material.dart';
import '../dark/theme_custom_dark.dart';

ThemeData get themeGlobalUltraDark {
  const Color inputBackgroundColor = Color.fromRGBO(51, 57, 72, 1);
  const Color textColor = Color.fromRGBO(255, 255, 255, 1);

  OutlineInputBorder outlineBorderLight(Color lightAccentColor) =>
      OutlineInputBorder(
        borderSide: BorderSide(color: lightAccentColor),
        borderRadius: BorderRadius.circular(18),
      );

  final ColorScheme colorScheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color.fromRGBO(61, 119, 233, 1),
    primary: const Color.fromRGBO(61, 119, 233, 1),
    secondary: const Color.fromRGBO(90, 104, 230, 1),
    tertiary: const Color.fromRGBO(28, 32, 59, 1),
    surface: const Color(0xFF000000),
    onSurface: const Color(0xFF000000),
    error: const Color.fromRGBO(202, 78, 61, 1),
  );

  final TextTheme textTheme = TextTheme(
    headlineMedium: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    headlineSmall: const TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    titleLarge: const TextStyle(
      fontSize: 26.0,
      color: textColor,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: const TextStyle(fontSize: 18.0, color: textColor),
    bodyMedium: const TextStyle(
      fontSize: 16.0,
      color: textColor,
      fontWeight: FontWeight.w300,
    ),
    labelLarge: const TextStyle(fontSize: 16.0, color: textColor),
    bodyLarge: TextStyle(
      fontSize: 14.0,
      color: textColor.withAlpha(128),
    ),
    bodySmall: TextStyle(
      fontSize: 12.0,
      color: textColor.withAlpha(204),
      fontWeight: FontWeight.w400,
    ),
  );

  SnackBarThemeData snackBarThemeLight() => SnackBarThemeData(
        elevation: 12.0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.primaryContainer,
        contentTextStyle: textTheme.bodyLarge!.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        actionTextColor: colorScheme.onPrimaryContainer,
        showCloseIcon: true,
        closeIconColor: colorScheme.onPrimaryContainer.withAlpha(179),
      );

  final customTheme = ThemeCustomDark();
  final theme = ThemeData(
    useMaterial3: false,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: colorScheme.onSurface,
    cardColor: colorScheme.surface,
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    colorScheme: colorScheme,
    primaryColor: colorScheme.primary,
    dividerColor: const Color.fromRGBO(56, 67, 108, 1),
    appBarTheme: AppBarTheme(color: colorScheme.surface),
    iconTheme: IconThemeData(color: colorScheme.primary),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color.fromRGBO(14, 16, 27, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    canvasColor: colorScheme.surface,
    hintColor: const Color.fromRGBO(183, 187, 191, 1),
    snackBarTheme: snackBarThemeLight(),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: const Color.fromRGBO(57, 161, 238, 1),
      selectionColor: const Color.fromRGBO(
        57,
        161,
        238,
        1,
      ).withAlpha(77),
      selectionHandleColor: const Color.fromRGBO(57, 161, 238, 1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: outlineBorderLight(Colors.transparent),
      disabledBorder: outlineBorderLight(Colors.transparent),
      border: outlineBorderLight(Colors.transparent),
      focusedBorder: outlineBorderLight(Colors.transparent),
      errorBorder: outlineBorderLight(colorScheme.error),
      fillColor: inputBackgroundColor,
      focusColor: inputBackgroundColor,
      hoverColor: Colors.transparent,
      errorStyle: TextStyle(color: colorScheme.error),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
      hintStyle: TextStyle(
        color: textColor.withAlpha(148),
      ),
      labelStyle: TextStyle(
        color: textColor.withAlpha(148),
      ),
      prefixIconColor: textColor.withAlpha(148),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) return Colors.grey;
            return colorScheme.primary;
          },
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.purple,
        selectedBackgroundColor: colorScheme.primary,
        foregroundColor: textColor.withAlpha(179),
        selectedForegroundColor: textColor,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: textColor,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 2.0, color: colorScheme.primary),
        insets: const EdgeInsets.symmetric(horizontal: 18),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      checkColor: WidgetStateProperty.all<Color>(Colors.white),
      fillColor: WidgetStateProperty.all<Color>(colorScheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
    ),
    textTheme: textTheme,
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all<Color?>(
        colorScheme.primary.withAlpha(204),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: textColor,
      unselectedItemColor: const Color.fromRGBO(173, 175, 198, 1),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
    extensions: [customTheme],
  );

  customTheme.initializeThemeDependentColors(theme);

  return theme;
}
