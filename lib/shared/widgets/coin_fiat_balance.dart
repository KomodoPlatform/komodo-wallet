import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/auto_scroll_text.dart';

class CoinFiatBalance extends StatelessWidget {
  const CoinFiatBalance(
    this.coin, {
    super.key,
    this.style,
    this.isSelectable = false,
    this.isAutoScrollEnabled = false,
  });

  final Coin coin;
  final TextStyle? style;
  final bool isSelectable;
  final bool isAutoScrollEnabled;

  @override
  Widget build(BuildContext context) {
    final balanceStream = context.sdk.balances.watchBalance(coin.id);
    final fiatCurrency = context.select(
      (SettingsBloc bloc) => bloc.state.fiatCurrency,
    );

    final TextStyle mergedStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ).merge(style);

    return StreamBuilder<BalanceInfo>(
      stream: balanceStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final priceFuture = context.sdk.marketData
            .maybeFiatPrice(coin.id, fiatCurrency: fiatCurrency)
            .then((value) => value?.toDouble());
        final balanceInfo = snapshot.data!;

        return FutureBuilder<double?>(
          future: priceFuture,
          builder: (context, priceSnapshot) {
            final price = priceSnapshot.data ?? 0.0;
            final value = balanceInfo.spendable.toDouble() * price;
            final balanceStr = formatFiatValue(context, value);

            if (isAutoScrollEnabled) {
              return AutoScrollText(
                text: balanceStr,
                style: mergedStyle,
                isSelectable: isSelectable,
              );
            }

            return isSelectable
                ? SelectableText(balanceStr, style: mergedStyle)
                : Text(balanceStr, style: mergedStyle);
          },
        );
      },
    );
  }
}
