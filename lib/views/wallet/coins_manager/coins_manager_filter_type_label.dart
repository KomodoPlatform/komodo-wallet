import 'package:flutter/material.dart';

class CoinsManagerFilterTypeLabel extends StatelessWidget {
  const CoinsManagerFilterTypeLabel({
    Key? key,
    required this.text,
    required this.backgroundColor,
    this.textStyle,
    required this.onTap,
    this.border,
  }) : super(key: key);
  final String text;
  final Color backgroundColor;
  final Border? border;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style:
                  textStyle ??
                  const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.close,
                size: 18,
                color: textStyle?.color ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
