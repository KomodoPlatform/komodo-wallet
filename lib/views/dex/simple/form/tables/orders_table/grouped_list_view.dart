import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/simple/form/tables/coins_table/coins_table_item.dart';
import 'package:web_dex/views/market_maker_bot/coin_search_dropdown.dart'
    as coin_dropdown;

class GroupedListView<T> extends StatelessWidget {
  const GroupedListView({
    super.key,
    required this.items,
    required this.onSelect,
    required this.maxHeight,
  });

  final List<T> items;
  final Function(T) onSelect;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    final groupedItems = _groupList(context, items);

    // Add right padding to the last column if there are grouped items
    // to align the grouped and non-grouped
    final areGroupedItemsPresent = groupedItems.isNotEmpty &&
        groupedItems.entries
            .where((element) => element.value.length > 1)
            .isNotEmpty;
    final rightPadding = areGroupedItemsPresent
        ? const EdgeInsets.only(right: 52)
        : const EdgeInsets.all(0);

    return Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DexScrollbar(
          isMobile: isMobile,
          scrollController: scrollController,
          child: ListView.builder(
            controller: scrollController,
            primary: false,
            shrinkWrap: true,
            itemCount: groupedItems.length,
            itemBuilder: (BuildContext context, int index) {
              final group = groupedItems.entries.elementAt(index);
              return group.value.length > 1
                  ? ExpansionTile(
                      tilePadding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                      childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      initiallyExpanded: false,
                      title: CoinsTableItem<T>(
                        data: group.value.first,
                        coin: _createHeaderCoinData(context, group.value),
                        onSelect: onSelect,
                        isGroupHeader: true,
                        subtitleText: LocaleKeys.nNetworks
                            .tr(args: [group.value.length.toString()]),
                      ),
                      children: group.value
                          .map((item) => buildItem(context, item, onSelect))
                          .toList(),
                    )
                  : buildItem(
                      context,
                      group.value.first,
                      onSelect,
                      padding: rightPadding,
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget buildItem(
    BuildContext context,
    T item,
    dynamic onSelect, {
    EdgeInsets padding = const EdgeInsets.all(0),
  }) {
    return Padding(
      padding: padding,
      child: CoinsTableItem<T>(
        data: item,
        coin: getCoin(context, item),
        onSelect: onSelect,
      ),
    );
  }

  Coin _createHeaderCoinData(BuildContext context, List<T> list) {
    final firstCoin = getCoin(context, list.first);
    double totalBalance = list.fold(0, (sum, item) {
      final coin = getCoin(context, item);
      return sum + coin.balance;
    });

    final coin = firstCoin.dummyCopyWithoutProtocolData();
    return coin.copyWith(balance: totalBalance);
  }

  Map<String, List<T>> _groupList(BuildContext context, List<T> list) {
    Map<String, List<T>> grouped = {};
    for (final item in list) {
      final coin = getCoin(context, item);
      grouped.putIfAbsent(coin.name, () => []).add(item);
    }
    return grouped;
  }

  Coin getCoin(BuildContext context, T item) {
    final coinsState = RepositoryProvider.of<CoinsBloc>(context).state;
    if (item is Coin) {
      return item as Coin;
    } else if (item is coin_dropdown.CoinSelectItem) {
      return (coinsState.walletCoins[item.coinId] ??
          coinsState.coins[item.coinId])!;
    } else {
      final String coinId = (item as BestOrder).coin;
      return (coinsState.walletCoins[coinId] ?? coinsState.coins[coinId])!;
    }
  }
}
