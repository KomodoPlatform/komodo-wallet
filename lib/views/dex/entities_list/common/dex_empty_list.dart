import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';

class DexEmptyList extends StatelessWidget {
  const DexEmptyList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 70, 12, 70),
      alignment: Alignment.topCenter,
      child: Text(LocaleKeys.listIsEmpty.tr()),
    );
  }
}
