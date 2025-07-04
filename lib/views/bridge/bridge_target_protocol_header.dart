import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_form_group_header.dart';

class TargetProtocolHeader extends StatelessWidget {
  const TargetProtocolHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DexFormGroupHeader(
      title: LocaleKeys.to.tr().toUpperCase(),
    );
  }
}
