import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/shared/ui/gradient_border.dart';

class FormPlate extends StatelessWidget {
  const FormPlate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GradientBorder(
      innerColor: dexPageColors.frontPlate,
      gradient: dexPageColors.formPlateGradient,
      child: Container(
        constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: child,
      ),
    );
  }
}
