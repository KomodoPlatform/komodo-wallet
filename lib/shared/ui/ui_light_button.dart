import 'package:flutter/material.dart';

class UiLightButton extends StatelessWidget {
  const UiLightButton({
    Key? key,
    this.text = '',
    this.width = double.infinity,
    this.height = 48.0,
    this.prefix,
    this.backgroundColor,
    this.border,
    this.textStyle,
    required this.onPressed,
  }) : super(key: key);

  final String text;
  final TextStyle? textStyle;
  final double width;
  final double height;
  final Widget? prefix;
  final Color? backgroundColor;
  final BoxBorder? border;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        )
        .merge(textStyle);

    return Container(
      constraints: BoxConstraints.tightFor(width: width, height: height),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        border: border,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.zero),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          )),
          backgroundColor: WidgetStateProperty.all<Color?>(
              backgroundColor ?? Theme.of(context).colorScheme.surface),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefix != null) prefix!,
            Text(text, style: style),
          ],
        ),
      ),
    );
  }
}
