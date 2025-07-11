import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/router/state/wallet_state.dart';
import 'package:web_dex/shared/utils/extensions/sdk_extensions.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/information_popup.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_controls.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_helpers.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_list.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_list_header.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_selected_types_list.dart';

class CoinsManagerListWrapper extends StatefulWidget {
  const CoinsManagerListWrapper({super.key});

  @override
  State<CoinsManagerListWrapper> createState() =>
      _CoinsManagerListWrapperState();
}

class _CoinsManagerListWrapperState extends State<CoinsManagerListWrapper> {
  CoinsManagerSortData _sortData = const CoinsManagerSortData(
      sortDirection: SortDirection.none, sortType: CoinsManagerSortType.none);
  late InformationPopup _informationPopup;

  @override
  void initState() {
    _informationPopup = InformationPopup(context: context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CoinsManagerBloc, CoinsManagerState>(
      listenWhen: (previous, current) =>
          previous.isSwitching && !current.isSwitching,
      listener: (context, state) {
        if (!state.isSwitching) {
          routingState.walletState.action = coinsManagerRouteAction.none;
        }
      },
      child: BlocBuilder<CoinsManagerBloc, CoinsManagerState>(
        builder: (BuildContext context, CoinsManagerState state) {
          List<Coin> sortedCoins = _sortCoins([...state.coins]);

          if (!context.read<SettingsBloc>().state.testCoinsEnabled) {
            sortedCoins = removeTestCoins(sortedCoins);
          }

          final bool isAddAssets = state.action == CoinsManagerAction.add;

          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              CoinsManagerFilters(isMobile: isMobile),
              if (!isMobile)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CoinsManagerListHeader(
                    sortData: _sortData,
                    isAddAssets: isAddAssets,
                    onSortChange: _onSortChange,
                  ),
                ),
              SizedBox(height: isMobile ? 4.0 : 14.0),
              const CoinsManagerSelectedTypesList(),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: CoinsManagerList(
                        coinList: sortedCoins,
                        isAddAssets: isAddAssets,
                        onCoinSelect: _onCoinSelect,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onSortChange(CoinsManagerSortData sortData) {
    setState(() {
      _sortData = sortData;
    });
  }

  List<Coin> _sortCoins(List<Coin> coins) {
    switch (_sortData.sortType) {
      case CoinsManagerSortType.name:
        return sortByName(coins, _sortData.sortDirection);
      case CoinsManagerSortType.protocol:
        return sortByProtocol(coins, _sortData.sortDirection);
      case CoinsManagerSortType.balance:
        return sortByUsdBalance(coins, _sortData.sortDirection, context.sdk);
      case CoinsManagerSortType.none:
        return sortByPriorityAndBalance(coins, context.sdk);
    }
  }

  void _onCoinSelect(Coin coin) {
    final tradingEntitiesBloc =
        RepositoryProvider.of<TradingEntitiesBloc>(context);
    final bloc = context.read<CoinsManagerBloc>();

    if (bloc.state.action == CoinsManagerAction.remove) {
      final childCoins = bloc.state.coins
          .where((c) => c.parentCoin?.abbr == coin.abbr)
          .toList();

      final hasSwap = tradingEntitiesBloc.hasActiveSwap(coin.abbr) ||
          childCoins.any((c) => tradingEntitiesBloc.hasActiveSwap(c.abbr));

      if (hasSwap) {
        _informationPopup.text =
            LocaleKeys.coinDisableSpan1.tr(args: [coin.abbr]);
        _informationPopup.show();
        return;
      }

      final int openOrders = tradingEntitiesBloc.openOrdersCount(coin.abbr) +
          childCoins.fold<int>(
              0, (sum, c) => sum + tradingEntitiesBloc.openOrdersCount(c.abbr));

      if (openOrders > 0) {
        confirmCoinDisableWithOrders(
          context,
          coin: coin.abbr,
          ordersCount: openOrders,
        ).then((confirmed) {
          if (!confirmed) return;
          tradingEntitiesBloc.cancelOrdersForCoin(coin.abbr);
          for (final child in childCoins) {
            tradingEntitiesBloc.cancelOrdersForCoin(child.abbr);
          }
          _confirmDisable(bloc, coin, childCoins);
        });
        return;
      }

      _confirmDisable(bloc, coin, childCoins);
      return;
    }

    bloc.add(CoinsManagerCoinSelect(coin: coin));
  }

  void _confirmDisable(
    CoinsManagerBloc bloc,
    Coin coin,
    List<Coin> childCoins,
  ) {
    if (coin.parentCoin == null) {
      final childTokens = childCoins.map((c) => c.abbr).toList();
      confirmParentCoinDisable(
        context,
        parent: coin.abbr,
        tokens: childTokens,
      ).then((confirmed) {
        if (confirmed) {
          bloc.add(CoinsManagerCoinSelect(coin: coin));
        }
      });
    } else {
      bloc.add(CoinsManagerCoinSelect(coin: coin));
    }
  }
}

enum CoinsManagerSortType {
  protocol,
  balance,
  name,
  none,
}

class CoinsManagerSortData implements SortData<CoinsManagerSortType> {
  const CoinsManagerSortData({
    required this.sortDirection,
    required this.sortType,
  });

  @override
  final CoinsManagerSortType sortType;
  @override
  final SortDirection sortDirection;
}
