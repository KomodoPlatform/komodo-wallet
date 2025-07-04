import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/views/dex/simple/form/common/dex_form_group_header.dart';

class TargetProtocolHeader extends StatelessWidget {
  const TargetProtocolHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DexFormGroupHeader(
      title: LocaleKeys.to.tr().toUpperCase(),
    );
  }
}
