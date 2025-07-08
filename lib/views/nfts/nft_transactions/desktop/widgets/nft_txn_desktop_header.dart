import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/nfts/nft_transactions/desktop/widgets/nft_txn_desktop_wrapper.dart';

class NftTxnDesktopHeader extends StatelessWidget {
  const NftTxnDesktopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? const _CoinsListHeaderMobile()
        : const _CoinsListHeaderDesktop();
  }
}

class _CoinsListHeaderDesktop extends StatelessWidget {
  const _CoinsListHeaderDesktop();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>();
    final textScheme = Theme.of(context).extension<TextThemeExtension>();
    final style = textScheme?.bodyXS.copyWith(
      color: colorScheme?.s50,
    );
    return NftTxnDesktopWrapper(
      firstChild: Text(LocaleKeys.status.tr(), style: style),
      secondChild: Text(LocaleKeys.blockchain.tr(), style: style),
      thirdChild: Text(LocaleKeys.nft.tr(), style: style),
      fourthChild: Text(LocaleKeys.date.tr(), style: style),
      fifthChild: Text(LocaleKeys.hash.tr(), style: style),
    );
  }
}

class _CoinsListHeaderMobile extends StatelessWidget {
  const _CoinsListHeaderMobile();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
