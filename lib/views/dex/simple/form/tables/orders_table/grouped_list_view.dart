import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart' as mm2;
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/simple/form/tables/coins_table/coins_table_item.dart';

class GroupedListView<T> extends StatelessWidget {
  const GroupedListView({
    required this.items,
    required this.onSelect,
    required this.maxHeight,
    super.key,
  });

  final List<T> items;
  final void Function(T) onSelect;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    final groupedItems = _groupList(context, items);

    // Add right padding to the last column if there are grouped items
    // to align the grouped and non-grouped
    final areGroupedItemsPresent =
        groupedItems.isNotEmpty &&
        groupedItems.entries
            .where((element) => element.value.length > 1)
            .isNotEmpty;
    final rightPadding = areGroupedItemsPresent
        ? const EdgeInsets.only(right: 52)
        : EdgeInsets.zero;

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
                        subtitleText: LocaleKeys.nNetworks.tr(
                          args: [group.value.length.toString()],
                        ),
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
    void Function(T) onSelect, {
    EdgeInsets padding = EdgeInsets.zero,
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
    final sdk = GetIt.I<KomodoDefiSdk>();

    final totalBalance = list.fold<BalanceInfo>(BalanceInfo.zero(), (
      sum,
      item,
    ) {
      final coin = getCoin(context, item);
      final coinBalance = sdk.balances.lastKnown(coin.id) ?? BalanceInfo.zero();
      return sum + coinBalance;
    });

    final coin = firstCoin.dummyCopyWithoutProtocolData();
    // Since we can't use 'balance' property directly anymore, we need to
    // construct the coin without using the balance property
    return coin.copyWith(sendableBalance: totalBalance.spendable.toDouble());
  }

  Map<String, List<T>> _groupList(BuildContext context, List<T> list) {
    final Map<String, List<T>> grouped = {};
    for (final item in list) {
      final coin = getCoin(context, item);
      grouped.putIfAbsent(coin.displayName, () => []).add(item);
    }
    return grouped;
  }

  Coin getCoin(BuildContext context, T item) {
    final coinsState = RepositoryProvider.of<CoinsBloc>(context).state;
    if (item is Coin) {
      return item as Coin;
    } else if (item is SelectItem) {
      return (coinsState.walletCoins[item.id] ?? coinsState.coins[item.id])!;
    } else {
      final String coinId = (item as mm2.BestOrder).coin;
      return (coinsState.walletCoins[coinId] ?? coinsState.coins[coinId])!;
    }
  }
}
