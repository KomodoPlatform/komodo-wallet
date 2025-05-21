# Migrating from `easy_localization` to Flutter's Built-in Localization

This document outlines the recommended steps to migrate the Komodo Wallet application from using the `easy_localization` package to Flutter's built-in internationalization and localization tools.

## 1. Analyse the Current Implementation

- All translations currently live in `assets/translations/en.json` and a generated Dart file `lib/generated/codegen_loader.g.dart` provides `LocaleKeys`.
- Widgets obtain translations using `LocaleKeys.someKey.tr()` or `context.tr()` helpers.
- The app is wrapped in `EasyLocalization` in `main.dart` and `MaterialApp.router` consumes `context.locale` and similar APIs.

## 2. Update Dependencies

1. Remove the `easy_localization` dependency from `pubspec.yaml`.
2. Add Flutter's localization packages:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.0 # or the latest supported by Flutter
```

## 3. Prepare ARB Translation Files

1. Create a directory `lib/l10n`.
2. Convert `assets/translations/en.json` to `lib/l10n/intl_en.arb`. ARB files use the same JSON format but support placeholders and metadata. Example:

```json
{
  "helloWorld": "Hello World!",
  "maxAmount": "Max amount is {amount} {coinAbbr}, please select other amount",
  "@maxAmount": {
    "placeholders": {
      "amount": {},
      "coinAbbr": {}
    }
  }
}
```

3. Repeat for additional languages if they exist (e.g. `intl_fr.arb`).
4. Delete or archive the `assets/translations` folder once conversion is complete.

## 4. Configure the Localization Generator

1. Add the following to the root of `pubspec.yaml`:

```yaml
flutter:
  generate: true
```

2. Optionally create a `l10n.yaml` file to customise the generator:

```yaml
arb-dir: lib/l10n
template-arb-file: intl_en.arb
output-localization-file: app_localizations.dart
```

3. Run the generator:

```bash
flutter pub get --offline
flutter gen-l10n
```

Flutter generates `lib/l10n/app_localizations.dart` containing `AppLocalizations` and a list of supported locales.

## 5. Update Application Initialization

1. Remove the `EasyLocalization` widget wrapper in `main.dart`.
2. Import the generated `AppLocalizations` and Flutter delegates:

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
```

3. Update `MaterialApp.router` (or `MaterialApp`) configuration:

```dart
return MaterialApp.router(
  onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: _userPreferredLocale, // your current locale logic
  ...
);
```

The delegates list includes `GlobalMaterialLocalizations.delegate` and others automatically.

## 6. Replace Translation Lookups

1. Delete `lib/generated/codegen_loader.g.dart` and any `LocaleKeys` imports.
2. Use the generated localization class to obtain strings:

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.helloWorld);
Text(l10n.maxAmount(amount, coinAbbr)); // for placeholders
```

3. For pluralization, use the generated plural methods or `Intl.plural` inside `AppLocalizations`.
4. Search the codebase for `.tr(`, `context.tr(`, and `LocaleKeys` to replace all usages.

## 7. Update Runtime Locale Handling

`EasyLocalization` exposed helpers like `context.locale` and `context.setLocale`. Replace them with your own state management or with `AppLocalizations` APIs:

- Store the user selected locale in settings.
- Pass the locale to `MaterialApp.router` via the `locale` property.
- To change language, update the stored locale and rebuild the app.

## 8. Update Tests and Documentation

1. Remove references to `easy_localization` in tests and update any mocks or helpers.
2. Replace `docs/LOCALIZATION.md` instructions with the new approach, referencing this plan during migration.
3. Clean up leftover configuration or scripts that invoke `easy_localization:generate`.

## 9. Final Cleanup

- Ensure `flutter analyze` passes and format the code with `dart format .`.
- Remove the `easy_localization` configuration files and unused assets.
- Commit all new ARB files and the updated `pubspec.lock` after running `flutter pub get --offline`.

Following these steps will fully migrate the project to Flutter's built-in localization system. Consult the [Flutter internationalization docs](https://docs.flutter.dev/development/accessibility-and-localization/internationalization) for additional details on ARB syntax and advanced usage.
