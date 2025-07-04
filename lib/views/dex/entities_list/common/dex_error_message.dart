import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';

class DexErrorMessage extends StatelessWidget {
  const DexErrorMessage();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 70, 12, 70),
      alignment: Alignment.topCenter,
      child: Text(
        LocaleKeys.dexErrorMessage.tr(),
        style: TextStyle(color: themeData.colorScheme.error),
      ),
    );
  }
}
