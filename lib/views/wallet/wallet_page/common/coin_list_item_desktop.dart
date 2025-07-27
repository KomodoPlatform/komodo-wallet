import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/ui/ui_simple_border_button.dart';
import 'package:web_dex/shared/widgets/coin_fiat_price.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:web_dex/shared/widgets/need_attention_mark.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/coin_sparkline.dart';

class CoinListItemDesktop extends StatelessWidget {
  const CoinListItemDesktop({
    super.key,
    required this.coin,
    required this.backgroundColor,
    required this.onTap,
  });

  final Coin coin;
  final Color backgroundColor;
  final Function(Coin) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: backgroundColor,
      ),
      child: Material(
        // type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: theme.custom.zebraHoverColor,
          onTap: coin.isActivating ? null : () => onTap(coin),
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 16, 10),
            child: Row(
              key: Key('coin-item-${(coin.abbr).toLowerCase()}'),
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      NeedAttentionMark(coin.isSuspended),
                      const SizedBox(width: 11),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CoinItem(
                            coin: coin,
                            size: CoinItemSize.large,
                            heroTag: coin.id.id,
                          ),
                          if (coin.isActivating)
                            const Positioned(
                              top: 4,
                              right: -20,
                              child: UiSpinner(
                                width: 12,
                                height: 12,
                                strokeWidth: 1.5,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 24.0),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: coin.isSuspended
                      ? const SizedBox.shrink()
                      : CoinFiatPrice(
                          coin,
                          style: const TextStyle(fontSize: _fontSize),
                        ),
                ),
                Expanded(
                  flex: 2,
                  child: CoinSparkline(coinId: coin.abbr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuspendedMessage extends StatelessWidget {
  const _SuspendedMessage({
    required this.coin,
    required this.isReEnabling,
  });

  final Coin coin;
  final bool isReEnabling;

  @override
  Widget build(BuildContext context) {
    final coinsBloc = context.read<CoinsBloc>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.6,
          child: Text(
            LocaleKeys.activationFailedMessage.tr(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 1.0),
          child: UiSimpleBorderButton(
            key: Key('retry-suspended-asset-${(coin.abbr)}'),
            onPressed: isReEnabling
                ? null
                : () => coinsBloc.add(CoinsActivated([coin.abbr])),
            inProgress: isReEnabling,
            child: const Text(LocaleKeys.retryButtonText).tr(),
          ),
        ),
      ],
    );
  }
}

const double _fontSize = 14;
