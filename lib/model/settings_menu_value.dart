import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';

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
