import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/wallets_manager/widgets/custom_seed_dialog.dart';

class CustomSeedCheckbox extends StatelessWidget {
  const CustomSeedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return UiCheckbox(
      checkboxKey: const Key('checkbox-custom-seed'),
      value: value,
      text: LocaleKeys.useCustomSeedOrWif.tr(),
      onChanged: (newValue) async {
        if (!value && newValue) {
          final confirmed = await customSeedDialog(context);
          if (!confirmed) return;
        }

        onChanged(newValue);
      },
    );
  }
}
