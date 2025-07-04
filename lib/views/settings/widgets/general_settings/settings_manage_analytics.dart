import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/shared/widgets/send_analytics_checkbox.dart';
import 'package:komodo_wallet/views/settings/widgets/common/settings_section.dart';

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
