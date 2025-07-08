import 'package:web_dex/localization/app_localizations.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

enum SettingsMenuValue {
  general,
  security,
  support,
  feedback,
  none;

  String get title {
    switch (this) {
      case SettingsMenuValue.general:
        return LocaleKeys.settingsMenuGeneral.tr();
      case SettingsMenuValue.security:
        return LocaleKeys.settingsMenuSecurity.tr();
      case SettingsMenuValue.support:
        return LocaleKeys.support.tr();
      case SettingsMenuValue.feedback:
        return LocaleKeys.feedback.tr();
      case SettingsMenuValue.none:
        return '';
    }
  }

  String get name {
    switch (this) {
      case SettingsMenuValue.general:
        return 'general';
      case SettingsMenuValue.security:
        return 'security';
      case SettingsMenuValue.support:
        return 'support';
      case SettingsMenuValue.feedback:
        return 'feedback';
      case SettingsMenuValue.none:
        return 'none';
    }
  }
}
