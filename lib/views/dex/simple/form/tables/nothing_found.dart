import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

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
