import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class BridgeGroup extends StatelessWidget {
  const BridgeGroup({this.header, required this.child});

  final Widget? header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) header!,
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 6, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.custom.dexPageTheme.frontPlate,
              border: Border.all(
                width: 1,
                color: theme.currentGlobal.dividerColor,
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}
