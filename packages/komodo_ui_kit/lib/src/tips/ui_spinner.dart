import 'package:flutter/material.dart';

class UiSpinner extends StatelessWidget {
  const UiSpinner({
    super.key,
    this.height = 20,
    this.width = 20,
    this.repeat = true,
    this.strokeWidth = 2,
    this.color,
  });
  final double width;
  final double height;
  final bool repeat;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}
