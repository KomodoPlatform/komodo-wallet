import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class NeedAttentionMark extends StatelessWidget {
  const NeedAttentionMark(this.needAttention, {Key? key}) : super(key: key);

  final bool needAttention;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 25,
      decoration: BoxDecoration(
          color: needAttention ? theme.custom.warningColor : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(18))),
    );
  }
}
