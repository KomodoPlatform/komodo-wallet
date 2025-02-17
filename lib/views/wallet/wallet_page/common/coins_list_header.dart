import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class CoinsListHeader extends StatelessWidget {
  const CoinsListHeader({
    super.key,
    required this.isAuth,
  });

  final bool isAuth;

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? const SizedBox.shrink()
        : _CoinsListHeaderDesktop(isAuth: isAuth);
  }
}

class _CoinsListHeaderDesktop extends StatelessWidget {
  const _CoinsListHeaderDesktop({
    required this.isAuth,
  });

  final bool isAuth;

  @override
  Widget build(BuildContext context) {
    // final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
    //       fontWeight: FontWeight.w500,
    //     );
    final style = Theme.of(context).textTheme.labelSmall;

    if (isAuth) {
      return Row(
        children: [
          // Expand button space
          SizedBox(width: 32),

          // Asset header
          Container(
            constraints: const BoxConstraints(maxWidth: 180),
            width: double.infinity,
            alignment: Alignment.centerLeft,
            child: Text(LocaleKeys.asset.tr(), style: style),
          ),

          const Spacer(),

          // Balance header
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(LocaleKeys.balance.tr(), style: style),
            ),
          ),

          // 24h change header
          Container(
            width: 68,
            alignment: Alignment.centerLeft,
            child: Text(LocaleKeys.change24hRevert.tr(), style: style),
          ),

          const Spacer(),

          // // More actions space
          const SizedBox(width: 48),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          // Asset header
          Text(LocaleKeys.asset.tr(), style: style),

          const Spacer(flex: 4),

          // Balance header
          Text(LocaleKeys.balance.tr(), style: style),

          const Spacer(flex: 2),

          // 24h change header
          Padding(
            padding: const EdgeInsets.only(right: 48),
            child: Text(LocaleKeys.change24hRevert.tr(), style: style),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
