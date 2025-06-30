import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../app_config/app_config.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late final Map<String, dynamic> _localizedStrings;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    final jsonString = await rootBundle
        .loadString('$assetsPath/translations/${locale.languageCode}.json');
    localizations._localizedStrings =
        json.decode(jsonString) as Map<String, dynamic>;
    return localizations;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String tr(String key, {List<String>? args, Map<String, String>? namedArgs}) {
    var value = _localizedStrings[key];
    if (value == null) return key;
    if (value is Map) {
      value = value['other'] ?? '';
    }
    var result = value.toString();
    if (namedArgs != null) {
      namedArgs.forEach((k, v) {
        result = result.replaceAll('{$k}', v);
      });
    }
    if (args != null) {
      for (final arg in args) {
        result = result.replaceFirst(RegExp(r'\{}'), arg.toString());
      }
    }
    return result;
  }

  String plural(String key, num howMany,
      {List<String>? args, Map<String, String>? namedArgs}) {
    final value = _localizedStrings[key];
    if (value is Map<String, dynamic>) {
      var result = Intl.plural(
        howMany,
        zero: value['zero'],
        one: value['one'],
        two: value['two'],
        few: value['few'],
        many: value['many'],
        other: value['other'],
        locale: locale.languageCode,
      );
      if (namedArgs != null) {
        namedArgs.forEach((k, v) => result = result.replaceAll('{$k}', v));
      }
      if (args != null) {
        for (final arg in args) {
          result = result.replaceFirst(RegExp(r'\{}'), arg.toString());
        }
      }
      return result;
    }
    return tr(key, args: args, namedArgs: namedArgs);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      localeList.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.load(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension LocalizationStringExtension on String {
  String tr(BuildContext context,
          {List<String>? args, Map<String, String>? namedArgs}) =>
      AppLocalizations.of(context).tr(this, args: args, namedArgs: namedArgs);

  String plural(BuildContext context, num howMany,
          {List<String>? args, Map<String, String>? namedArgs}) =>
      AppLocalizations.of(context)
          .plural(this, howMany, args: args, namedArgs: namedArgs);
}

extension LocalizationBuildContextExtension on BuildContext {
  Locale get locale => Localizations.localeOf(this);

  List<Locale> get supportedLocales => localeList;

  List<LocalizationsDelegate<dynamic>> get localizationDelegates => const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];
}
