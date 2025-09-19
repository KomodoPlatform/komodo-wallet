import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class DexInfoContainer extends StatelessWidget {
  final List<Widget> children;

  const DexInfoContainer({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: dexPageColors.frontPlateBorder,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
