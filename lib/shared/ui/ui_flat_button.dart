import 'package:flutter/material.dart';

class UiFlatButton extends StatelessWidget {
  const UiFlatButton({
    Key? key,
    this.text = '',
    this.width = double.infinity,
    this.height = 48.0,
    this.backgroundColor,
    this.textStyle,
    this.shadow = false,
    required this.onPressed,
  }) : super(key: key);

  final String text;
  final TextStyle? textStyle;
  final bool shadow;
  final double width;
  final double height;
  final Gradient? backgroundColor;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.tightFor(width: width, height: height),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        boxShadow: shadow
            ? [
                BoxShadow(
                  offset: const Offset(0, 0),
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withAlpha(20) ??
                      Colors.transparent,
                  spreadRadius: 3,
                  blurRadius: 5,
                ),
              ]
            : null,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
          ),
          backgroundColor: shadow
              ? WidgetStateProperty.all<Color?>(Theme.of(context).cardColor)
              : null,
        ),
        child: Text(
          text,
          style:
              textStyle ??
              Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
        ),
      ),
    );
  }
}
