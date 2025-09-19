import 'package:flutter/material.dart';

class Hyperlink extends StatefulWidget {
  const Hyperlink({
    required this.text,
    required this.onPressed,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;

  @override
  State<Hyperlink> createState() => _HyperlinkState();
}

class _HyperlinkState extends State<Hyperlink> {
  Color hyperlinkTextColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      onHover: (isHover) {
        setState(() {
          hyperlinkTextColor = isHover ? Colors.blue.shade300 : Colors.blue;
        });
      },
      onTap: widget.onPressed,
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 0.2,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: hyperlinkTextColor,
              width: 0.5,
            ),
          ),
        ),
        child: Text(
          widget.text,
          style: TextStyle(color: hyperlinkTextColor),
        ),
      ), // () => launchURL(widget.url),
    );
  }
}
