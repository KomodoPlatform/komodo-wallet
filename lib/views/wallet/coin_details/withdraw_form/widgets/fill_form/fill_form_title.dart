import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/coin.dart';

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
