import 'package:flutter/material.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/widgets/coin_balance.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/item_decoration.dart';

class CoinsTableItem<T> extends StatelessWidget {
  const CoinsTableItem({
    super.key,
    required this.data,
    required this.onSelect,
    required this.coin,
    this.isGroupHeader = false,
    this.subtitleText,
  });

  final T? data;
  final Coin coin;
  final Function(T) onSelect;
  final bool isGroupHeader;
  final String? subtitleText;

  @override
  Widget build(BuildContext context) {
    final child = ItemDecoration(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          CoinItem(
            coin: coin,
            size: CoinItemSize.large,
            subtitleText: subtitleText,
            showNetworkLogo: !isGroupHeader,
          ),
          const SizedBox(width: 8),
          if (coin.isActive) CoinBalance(coin: coin, isVertical: true),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: isGroupHeader
          ? child
          : InkWell(
              key: Key('${T.toString()}-table-item-${coin.abbr}'),
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelect(data as T),
              child: child,
            ),
    );
  }
}
