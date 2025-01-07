import 'package:flutter/material.dart';
import 'package:web_dex/views/settings/widgets/security_settings/plate_seed_backup.dart';

class SecuritySettingsMainPage extends StatelessWidget {
  const SecuritySettingsMainPage({required this.onViewSeedPressed});
  final Function(BuildContext context) onViewSeedPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlateSeedBackup(onViewSeedPressed: onViewSeedPressed),
        // TODO!: re-enable once implemented
        // const SizedBox(height: 12),
        // const ChangePasswordSection(),
      ],
    );
  }
}
