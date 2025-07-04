import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/widgets/send_analytics_checkbox.dart';
import 'package:web_dex/views/settings/widgets/common/settings_section.dart';

class SettingsManageAnalytics extends StatelessWidget {
  const SettingsManageAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: LocaleKeys.manageAnalytics.tr(),
      child: const SendAnalyticsCheckbox(),
    );
  }
}
