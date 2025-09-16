import 'package:flutter/material.dart';

class GradientBorder extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final double width;
  final BorderRadius borderRadius;
  final Color innerColor;

  const GradientBorder({
    Key? key,
    required this.child,
    required this.gradient,
    required this.innerColor,
    this.width = 1.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: gradient,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: innerColor,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}
