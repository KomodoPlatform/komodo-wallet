import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EntityItemStatusWrapper extends StatelessWidget {
  const EntityItemStatusWrapper({
    Key? key,
    required this.text,
    required this.icon,
    required this.width,
    required this.backgroundColor,
    required this.textColor,
  }) : super(key: key);

  final String text;
  final double width;
  final Widget icon;
  final Color backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    assert(icon is Icon || icon is SvgPicture);

    return Container(
      padding: const EdgeInsets.all(8),
      constraints: BoxConstraints.tightFor(width: width),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9), color: backgroundColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
