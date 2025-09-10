import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class NftTxnEmpty extends StatelessWidget {
  const NftTxnEmpty();

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? const Center(child: _NothingShow())
        : Container(
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 72.0),
            child: const _NothingShow(),
          );
  }
}

class _NothingShow extends StatelessWidget {
  const _NothingShow();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(LocaleKeys.transactionsEmptyTitle.tr(), style: textTheme.heading1),
        const SizedBox(height: 16),
        Text(
          LocaleKeys.transactionsEmptyDescription.tr(),
          style: textTheme.bodyM,
        ),
      ],
    );
  }
}
