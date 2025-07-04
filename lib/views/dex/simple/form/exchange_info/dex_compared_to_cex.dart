import 'dart:math';

import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rational/rational.dart';
import 'package:komodo_wallet/app_config/app_config.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/ui/custom_tooltip.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';
import 'package:komodo_wallet/views/dex/dex_helpers.dart';

class DexComparedToCex extends StatelessWidget {
  const DexComparedToCex({
    required this.base,
    required this.rel,
    required this.rate,
  });

  final Coin? base;
  final Coin? rel;
  final Rational? rate;

  @override
  Widget build(BuildContext context) {
    final double? baseUsd = base?.usdPrice?.price;
    final double? relUsd = rel?.usdPrice?.price;

    double diff = 0;
    if (baseUsd != null && relUsd != null && rate != null) {
      diff = compareToCex(baseUsd, relUsd, rate!);
    }

    return _View(diff);
  }
}

class _View extends StatelessWidget {
  const _View(this.diff);

  final double diff;

  @override
  Widget build(BuildContext context) {
    const header = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    Color? color = header.color;
    if (diff > 0) {
      color = theme.custom.increaseColor;
    } else if (diff < 0) {
      color = theme.custom.decreaseColor;
    }

    final double maxWidth = min(220, screenWidth - 190);
    final style = header.copyWith(color: color);
    return Row(
      children: [
        Text(LocaleKeys.comparedToCexTitle.tr(), style: header),
        const SizedBox(width: 7),
        CustomTooltip(
          tooltip: Text(
            LocaleKeys.comparedToCexInfo.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          maxWidth: maxWidth,
          child: SvgPicture.asset(
            '$assetsPath/others/round_question_mark.svg',
            colorFilter: ColorFilter.mode(
              Theme.of(context).textTheme.bodySmall?.color ?? Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
        const Spacer(),
        Text('${formatAmt(diff)}%', style: style),
      ],
    );
  }
}
