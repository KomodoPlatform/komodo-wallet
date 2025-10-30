import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';

class CoinTradeAmountLabel extends StatelessWidget {
  const CoinTradeAmountLabel({
    required this.value,
    super.key,
    this.coin,
    this.errorText,
  });

  final Coin? coin;
  final Rational value;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 18, top: 1),
            child: TradeAmountDisplayText(
              key: const Key('maker-amount-display'),
              value: value,
              coin: coin,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: TradeAmountFiatPriceText(
              key: const Key('maker-amount-fiat'),
              coin: coin,
              amount: value,
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: AutoScrollText(
                text: errorText!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class TradeAmountFiatPriceText extends StatelessWidget {
  const TradeAmountFiatPriceText({super.key, this.coin, this.amount});

  final Rational? amount;
  final Coin? coin;

  @override
  Widget build(BuildContext context) {
    return Text(
      coin == null
          ? r'≈$0'
          : getFormattedFiatAmount(
              context,
              coin!.abbr,
              amount ?? Rational.zero,
            ),
      style: Theme.of(context).textTheme.bodySmall,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class TradeAmountDisplayText extends StatelessWidget {
  const TradeAmountDisplayText({super.key, required this.value, this.coin});

  final Rational value;
  final Coin? coin;

  @override
  Widget build(BuildContext context) {
    final formattedValue = value.toDouble().toStringAsFixed(
      coin?.decimals ?? 8,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            formattedValue,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: dexPageColors.activeText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '*',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontFeatures: [const FontFeature.superscripts()],
          ),
        ),
      ],
    );
  }
}
