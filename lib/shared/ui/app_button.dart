import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppDefaultButton extends StatefulWidget {
  const AppDefaultButton({
    Key? key,
    required this.text,
    this.width = 150,
    this.height = 45,
    this.padding = const EdgeInsets.symmetric(vertical: 10),
    this.textStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    required this.onPressed,
  }) : super(key: key);

  final String text;
  final TextStyle? textStyle;
  final double width;
  final double height;
  final Function onPressed;
  final EdgeInsets padding;

  @override
  State<AppDefaultButton> createState() => _AppButton();
}

class _AppButton extends State<AppDefaultButton> {
  bool hover = false;
  bool hasFocus = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: (_) => setState(() => hover = true),
        child: MouseRegion(
            onHover: (_) => setState(() => hover = true),
            onExit: (_) => setState(() => hover = false),
            child: Container(
              decoration: BoxDecoration(
                color: hover
                    ? theme.custom.buttonColorDefaultHover
                    : Theme.of(context).colorScheme.tertiary,
                border: Border.all(
                    color: hasFocus
                        ? theme.custom.buttonColorDefaultHover
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onFocusChange: (value) {
                  setState(() {
                    hasFocus = value;
                  });
                },
                key: Key('coin-details-${(widget.text).toLowerCase()}'),
                style: ElevatedButton.styleFrom(
                  padding: widget.padding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  minimumSize: Size(widget.width, widget.height),
                  maximumSize: Size(double.infinity, widget.height),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () {
                  widget.onPressed();
                },
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: widget.textStyle!.copyWith(
                    color: hover
                        ? theme.custom.buttonTextColorDefaultHover
                        : Theme.of(context).textTheme.labelLarge?.color,
                  ),
                ),
              ),
            )));
  }
}
