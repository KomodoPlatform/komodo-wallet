import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/widgets/coin_fiat_balance.dart';
import 'package:web_dex/shared/widgets/coin_fiat_change.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:web_dex/shared/widgets/need_attention_mark.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/coin_sparkline.dart';

class CoinListItemMobile extends StatelessWidget {
  const CoinListItemMobile({
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
      margin: const EdgeInsets.only(bottom: 0),
      child: InkWell(
        onTap: coin.isActivating ? null : () => onTap(coin),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                key: Key('active-coin-item-${(coin.abbr).toLowerCase()}'),
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
                  Spacer(),
                  SizedBox(
                    width: 80,
                    height: 32,
                    child: CoinSparkline(coinId: coin.abbr),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(width: 16),
                  _CoinBalance(coin: coin),
                  Spacer(),
                  //  24 hour change
                  CoinFiatChange(
                    coin,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: theme.custom.increaseColor,
                    ),
                  ),
                  Spacer(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinBalance extends StatelessWidget {
  const _CoinBalance({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            AssetBalanceText(
              coin.id,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 10),
            CoinFiatBalance(
              coin,
              style: TextStyle(
                color: theme.custom.increaseColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        coin.isSuspended
            ? const SizedBox.shrink()
            : CoinFiatChange(
                coin,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
      ],
    );
  }
}
