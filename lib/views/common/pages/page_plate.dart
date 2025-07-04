import 'package:flutter/material.dart';
import 'package:komodo_wallet/common/screen.dart';

class PagePlate extends StatelessWidget {
  const PagePlate({required this.child, this.noBackground = false});

  final Widget child;
  final bool noBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: noBackground ? null : Theme.of(context).cardColor,
        borderRadius: isDesktop ? BorderRadius.circular(18) : null,
      ),
      child: child,
    );
  }
}
