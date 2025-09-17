import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NftTxnDate extends StatelessWidget {
  final formatter = DateFormat('dd MMM yyyy, HH:mm', 'en_US');
  final DateTime blockTimestamp;
  NftTxnDate({required this.blockTimestamp});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).extension<TextThemeExtension>()?.bodyXS;
    return Text(formatter.format(blockTimestamp), style: textStyle);
  }
}
