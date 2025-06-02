import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:app_theme/app_theme.dart';

class HDWalletModeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool highlight;

  const HDWalletModeSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.highlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final warningColor = theme.custom.warningColor;
    return Container(
      decoration: highlight
          ? BoxDecoration(
              color: warningColor.withOpacity(0.1),
              border: Border.all(color: warningColor),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: SwitchListTile(
        title: Row(
          children: [
            Text(LocaleKeys.hdWalletModeSwitchTitle.tr()),
            const SizedBox(width: 8),
            Tooltip(
              message: LocaleKeys.hdWalletModeSwitchTooltip.tr(),
              child: const Icon(Icons.info, size: 16),
            ),
          ],
        ),
        subtitle: Text(
          LocaleKeys.hdWalletModeSwitchSubtitle.tr(),
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
