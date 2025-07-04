import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';

class NothingFound extends StatelessWidget {
  const NothingFound();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
      child: Text(
        LocaleKeys.nothingFound.tr(),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
