import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';

class PagePlate extends StatelessWidget {
  const PagePlate({
    required this.child,
    this.noBackground = true,
    this.padding = standardPadding,
    super.key,
  });

  final Widget child;
  final bool noBackground;
  final EdgeInsetsGeometry padding;

  static const EdgeInsets standardPadding = EdgeInsets.fromLTRB(15, 32, 15, 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      width: double.infinity,
      decoration: BoxDecoration(
        color: noBackground ? null : Theme.of(context).cardColor,
        borderRadius: isDesktop ? BorderRadius.circular(18) : null,
      ),
      child: child,
    );
  }
}
