import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/views/wallet/wallet_page/common/wallet_coins_list.dart';

class AllCoinsList extends StatelessWidget {
  const AllCoinsList({
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
    return BlocBuilder<CoinsBloc, CoinsState>(builder: (context, state) {
      final List<Coin> coins = state.coins.values.toList();

      if (coins.isEmpty) {
        return const SliverToBoxAdapter(child: UiSpinner());
      }

      List<Coin> displayedCoins =
          sortByPriority(filterCoinsByPhrase(coins, searchPhrase)).toList();

      if (!context.read<SettingsBloc>().state.testCoinsEnabled) {
        displayedCoins = removeTestCoins(displayedCoins);
      }

      return WalletCoinsList(
        coins: displayedCoins,
        onCoinItemTap: onCoinItemTap,
      );
    });
  }
}
