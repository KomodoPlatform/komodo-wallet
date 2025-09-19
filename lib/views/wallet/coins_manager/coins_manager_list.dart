import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_list_item.dart';

class CoinsManagerList extends StatelessWidget {
  CoinsManagerList({
    Key? key,
    required this.coinList,
    required this.isAddAssets,
    required this.onCoinSelect,
  }) : super(key: key);
  final List<Coin> coinList;
  final bool isAddAssets;
  final void Function(Coin) onCoinSelect;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final List<Coin> selectedCoins =
        context.watch<CoinsManagerBloc>().state.selectedCoins;

    return Material(
      color: Colors.transparent,
      child: DexScrollbar(
        scrollController: _scrollController,
        isMobile: isMobile,
        child: ListView.builder(
          key: const Key('coins-manager-list'),
          shrinkWrap: true,
          itemCount: coinList.length,
          controller: _scrollController,
          itemBuilder: (context, int i) {
            final Coin coin = coinList[i];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: CoinsManagerListItem(
                coin: coin,
                isSelected:
                    selectedCoins.where((c) => c.abbr == coin.abbr).isNotEmpty,
                isMobile: isMobile,
                isAddAssets: isAddAssets,
                onSelect: () => onCoinSelect(coin),
              ),
            );
          },
        ),
      ),
    );
  }
}
