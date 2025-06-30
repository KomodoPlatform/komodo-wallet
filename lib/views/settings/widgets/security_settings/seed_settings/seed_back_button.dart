import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/ui/ui_gradient_icon.dart';

class SeedBackButton extends StatelessWidget {
  const SeedBackButton(this.back);

  final VoidCallback back;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return InkWell(
      key: const Key('back-button'),
      radius: 30,
      onTap: back,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 9),
            const UiGradientIcon(icon: Icons.chevron_left, size: 24),
            const SizedBox(width: 14),
            Text(LocaleKeys.back.tr(), style: style),
            const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}
