import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class QuickLoginSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const QuickLoginSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Row(
        children: [
          Text(LocaleKeys.oneClickLogin.tr()),
          const SizedBox(width: 8),
          Tooltip(
            message: LocaleKeys.quickLoginTooltip.tr(),
            child: const Icon(Icons.info, size: 16),
          ),
        ],
      ),
      subtitle: Text(
        LocaleKeys.quickLoginSubtitle.tr(),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
