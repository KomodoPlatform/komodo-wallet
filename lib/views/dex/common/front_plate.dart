import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class FrontPlate extends StatelessWidget {
  const FrontPlate({required this.child, this.shadowEnabled = false});

  final Widget child;
  final bool shadowEnabled;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      spreadRadius: 0,
      blurRadius: 4,
      offset: const Offset(0, 4),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
      width: double.infinity,
      decoration: BoxDecoration(
        color: dexPageColors.frontPlateInner,
        borderRadius: borderRadius,
        boxShadow: shadowEnabled ? [shadow] : null,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}
