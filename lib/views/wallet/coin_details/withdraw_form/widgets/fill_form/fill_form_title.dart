import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';

class FillFormTitle extends StatelessWidget {
  const FillFormTitle(this.coinAbbr);

  final String coinAbbr;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SelectableText.rich(
        TextSpan(
            text: '${LocaleKeys.youSend.tr()}  ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: .4),
            ),
            children: [
              TextSpan(
                text: Coin.normalizeAbbr(coinAbbr),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ]),
      ),
    );
  }
}
