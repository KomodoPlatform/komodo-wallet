import 'package:flutter/material.dart';

class TruncatedMiddleText extends StatelessWidget {
  final String string;
  final TextStyle style;
  final int level;

  const TruncatedMiddleText(this.string,
      {this.style = const TextStyle(), this.level = 6, super.key});

  @override
  Widget build(BuildContext context) {
    if (string.length < level) {
      return Text(
        string,
        style: style,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Flexible(
          child: Text(
            string.substring(0, string.length - level + 1),
            key: key,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(fontFamily: 'Sans-Serif, Arial'),
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          string.substring(string.length - level + 1),
          style: style.copyWith(fontFamily: 'Sans-Serif, Arial'),
        ),
      ],
    );
  }
}
