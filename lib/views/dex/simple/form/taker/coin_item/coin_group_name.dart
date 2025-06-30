import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/app_assets.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/utils.dart';

class CoinGroupName extends StatelessWidget {
  const CoinGroupName({super.key, this.coin, this.opened = false});

  final Coin? coin;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    final title = _getTitleFromCoinId(coin?.abbr);
    final chevron = opened
        ? const DexSvgImage(
            path: Assets.dexChevronUp,
            colorFilter: ColorFilterEnum.expandMode,
          )
        : const DexSvgImage(
            path: Assets.dexChevronDown,
            colorFilter: ColorFilterEnum.expandMode,
          );

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: dexPageColors.activeText,
          ),
        ),
        const SizedBox(width: 4),
        chevron,
      ],
    );
  }

  String _getTitleFromCoinId(String? coinId) {
    final title = coinId != null
        ? abbr2TickerWithSuffix(coinId)
        : LocaleKeys.selectAToken.tr();

    return title;
  }
}
