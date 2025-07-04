import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class BridgeTableColumnHeads extends StatelessWidget {
  const BridgeTableColumnHeads();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(LocaleKeys.protocol.tr(), style: style),
            Text(LocaleKeys.balance.tr(), style: style),
          ],
        ),
      ),
    );
  }
}
