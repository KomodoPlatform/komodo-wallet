import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/views/wallet/wallet_page/common/wallet_coins_list.dart';

class ActiveCoinsList extends StatelessWidget {
  const ActiveCoinsList({
    Key? key,
    required this.searchPhrase,
    required this.withBalance,
    required this.onCoinItemTap,
  }) : super(key: key);
  final String searchPhrase;
  final bool withBalance;
  final Function(Coin) onCoinItemTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinsBloc, CoinsState>(
      builder: (context, state) {
        final coins = state.walletCoins.values.toList();
        final Iterable<Coin> displayedCoins = _getDisplayedCoins(coins);

        if (displayedCoins.isEmpty &&
            (searchPhrase.isNotEmpty || withBalance)) {
          return SliverToBoxAdapter(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8.0),
              child: SelectableText(LocaleKeys.walletPageNoSuchAsset.tr()),
            ),
          );
        }

        List<Coin> sorted = sortFiatBalance(displayedCoins.toList());

        if (!context.read<SettingsBloc>().state.testCoinsEnabled) {
          sorted = removeTestCoins(sorted);
        }

        return WalletCoinsList(
          coins: sorted,
          onCoinItemTap: onCoinItemTap,
        );
      },
    );
  }

  Iterable<Coin> _getDisplayedCoins(Iterable<Coin> coins) =>
      filterCoinsByPhrase(coins, searchPhrase).where((Coin coin) {
        if (withBalance) {
          return coin.balance > 0;
        }
        return true;
      }).toList();
}
