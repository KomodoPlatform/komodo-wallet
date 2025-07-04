import 'package:app_theme/app_theme.dart';
import 'package:badges/badges.dart' as badges;
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/nft_transactions/bloc/nft_transactions_filters.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';

class NftTxnMobileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final void Function() onSettingsPressed;
  final NftTransactionsFilter filters;
  const NftTxnMobileAppBar({
    required this.filters,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    final textScheme = Theme.of(context).extension<TextThemeExtension>();
    return PageHeader(
      title: LocaleKeys.transactionsHistory.tr(),
      onBackButtonPressed: routingState.nftsState.reset,
      actions: [
        IconButton(
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          icon: badges.Badge(
            showBadge: !filters.isEmpty,
            position: badges.BadgePosition.topEnd(top: -5, end: -5),
            badgeContent: Text('${filters.count}',
                style: textScheme?.bodyXXS.copyWith(color: colorScheme.surf)),
            badgeStyle: badges.BadgeStyle(
              badgeColor: colorScheme.primary,
            ),
            child: SvgPicture.asset(
              '$assetsPath/custom_icons/filter.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                filters.isEmpty ? colorScheme.secondary : colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
          onPressed: onSettingsPressed,
          color: colorScheme.secondary,
          iconSize: 20,
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size(double.infinity, 56);
}
