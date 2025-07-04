import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_bloc.dart';
import 'package:komodo_wallet/bloc/settings/settings_bloc.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/model/coin_utils.dart';
import 'package:komodo_wallet/views/wallet/wallet_page/common/wallet_coins_list.dart';

class AllCoinsList extends StatefulWidget {
  const AllCoinsList({
    super.key,
    required this.searchPhrase,
    required this.withBalance,
    required this.onCoinSelected,
  });
  final String searchPhrase;
  final bool withBalance;
  final Function(Coin) onCoinSelected;

  @override
  _AllCoinsListState createState() => _AllCoinsListState();
}

class _AllCoinsListState extends State<AllCoinsList> {
  List<Coin> displayedCoins = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDisplayedCoins();
  }

  @override
  void didUpdateWidget(AllCoinsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchPhrase != widget.searchPhrase) {
      _updateDisplayedCoins();
    }
  }

  void _updateDisplayedCoins() {
    final coins = context.read<CoinsBloc>().state.coins.values.toList();
    if (coins.isNotEmpty) {
      List<Coin> filteredCoins =
          sortByPriority(filterCoinsByPhrase(coins, widget.searchPhrase))
              .toList();
      if (!context.read<SettingsBloc>().state.testCoinsEnabled) {
        filteredCoins = removeTestCoins(filteredCoins);
      }
      setState(() {
        displayedCoins = filteredCoins;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoinsBloc, CoinsState>(
      listenWhen: (previous, current) => previous.coins != current.coins,
      listener: (context, state) {
        _updateDisplayedCoins();
      },
      builder: (context, state) {
        return state.coins.isEmpty
            ? const SliverToBoxAdapter(child: UiSpinner())
            : displayedCoins.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No coins found',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : KnownAssetsList(
                    assets: displayedCoins.map((c) => c.id).toList(),
                    onAssetItemTap: (id) {
                      final coin =
                          displayedCoins.firstWhere((coin) => coin.id == id);
                      widget.onCoinSelected(coin);
                    },
                  );
      },
    );
  }
}
