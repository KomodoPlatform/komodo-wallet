import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/shared/ui/ui_gradient_icon.dart';

class BackButtonDesktop extends StatelessWidget {
  const BackButtonDesktop({required this.text, required this.onPressed});
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('back-button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            SizedBox(
              height: 30,
              child: UiGradientIcon(
                icon: Icons.chevron_left,
                color: theme.custom.headerIconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.custom.headerIconColor,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
