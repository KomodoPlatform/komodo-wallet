import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class NftTxnDate extends StatelessWidget {
  final formatter = DateFormat('dd MMM yyyy, HH:mm', 'en_US');
  final DateTime blockTimestamp;
  NftTxnDate({required this.blockTimestamp});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).extension<TextThemeExtension>()?.bodyXS;
    return Text(
      formatter.format(blockTimestamp),
      style: textStyle,
    );
  }
}
