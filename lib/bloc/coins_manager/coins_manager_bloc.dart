import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Bloc, Emitter;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/analytics/events/portfolio_events.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_sort.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/state/wallet_state.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_helpers.dart';

part 'coins_manager_event.dart';
part 'coins_manager_state.dart';

class CoinsManagerBloc extends Bloc<CoinsManagerEvent, CoinsManagerState> {
  CoinsManagerBloc({
    required CoinsRepo coinsRepo,
    required KomodoDefiSdk sdk,
    required AnalyticsBloc analyticsBloc,
    required SettingsRepository settingsRepository,
    required TradingEntitiesBloc tradingEntitiesBloc,
  })  : _coinsRepo = coinsRepo,
        _sdk = sdk,
        _analyticsBloc = analyticsBloc,
        _settingsRepository = settingsRepository,
        _tradingEntitiesBloc = tradingEntitiesBloc,
        super(CoinsManagerState.initial(coins: [])) {
    on<CoinsManagerCoinsUpdate>(_onCoinsUpdate);
    on<CoinsManagerCoinsListReset>(_onCoinsListReset);
    on<CoinsManagerCoinTypeSelect>(_onCoinTypeSelect);
    on<CoinsManagerCoinsSwitch>(_onCoinsSwitch);
    // Sequential transformer is used to ensure that no concurrent updates
    // occur, which could lead to inconsistent state.
    // This is important for actions like selecting/deselecting coins, which
    // the user might perform rapidly.
    on<CoinsManagerCoinSelect>(_onCoinSelect);
    on<CoinsManagerSelectAllTap>(_onSelectAll);
    on<CoinsManagerSelectedTypesReset>(_onSelectedTypesReset);
    on<CoinsManagerSearchUpdate>(_onSearchUpdate);
    on<CoinsManagerSortChanged>(_onSortChanged);
    on<CoinsManagerCoinRemoveRequested>(_onCoinRemoveRequested);
    on<CoinsManagerCoinRemoveConfirmed>(_onCoinRemoveConfirmed);
    on<CoinsManagerCoinRemovalCancelled>(_onCoinRemovalCancelled);
    on<CoinsManagerErrorCleared>(_onErrorCleared);
  }

  final CoinsRepo _coinsRepo;
  final KomodoDefiSdk _sdk;
  final AnalyticsBloc _analyticsBloc;
  final SettingsRepository _settingsRepository;
  final TradingEntitiesBloc _tradingEntitiesBloc;
  final _log = Logger('CoinsManagerBloc');

  Future<void> _onCoinsUpdate(
    CoinsManagerCoinsUpdate event,
    Emitter<CoinsManagerState> emit,
  ) async {
    final List<FilterFunction> filters = [];

    List<Coin> list = mergeCoinLists(
      await _getOriginalCoinList(_coinsRepo, event.action),
      state.coins,
    );

    // Add wallet coins to selected coins if in add mode so that they
    // are displayed in the list with the checkbox selected. This is
    // necessary, since the UI does not consider the state of the coins
    // in the list, but only the selected coins.
    final selectedCoins = await _mergeWalletCoinsIfNeeded(
      state.selectedCoins,
      event.action,
    );

    final uniqueCombinedList = <Coin>{...list, ...selectedCoins}.toList();

    list = await _filterTestCoinsIfNeeded(uniqueCombinedList);

    if (state.searchPhrase.isNotEmpty) {
      filters.add(_filterByPhrase);
    }
    if (state.selectedCoinTypes.isNotEmpty) {
      filters.add(_filterByType);
    }

    for (final filter in filters) {
      list = filter(list);
    }

    list = _sortCoins(list, event.action, state.sortData);

    emit(state.copyWith(
      coins: list,
      action: event.action,
      selectedCoins: selectedCoins,
    ));
  }

  Future<void> _onCoinsListReset(
    CoinsManagerCoinsListReset event,
    Emitter<CoinsManagerState> emit,
  ) async {
    emit(
      state.copyWith(
        action: event.action,
        coins: [],
        selectedCoins: const [],
        searchPhrase: '',
        selectedCoinTypes: const [],
        isSwitching: false,
      ),
    );
    final List<Coin> coins = await _getOriginalCoinList(
      _coinsRepo,
      event.action,
    );

    // Add wallet coins to selected coins if in add mode so that they
    // are displayed in the list with the checkbox selected. This is
    // necessary, since the UI does not consider the state of the coins
    // in the list, but only the selected coins.
    final selectedCoins = await _mergeWalletCoinsIfNeeded(
      event.action == CoinsManagerAction.add
          ? coins.where((c) => c.isActive).toList()
          : <Coin>[],
      event.action,
    );

    final filteredCoins =
        await _filterTestCoinsIfNeeded({...coins, ...selectedCoins}.toList());
    final sortedCoins = _sortCoins(filteredCoins, event.action, state.sortData);

    emit(
      state.copyWith(
        coins: sortedCoins,
        action: event.action,
        selectedCoins: selectedCoins,
      ),
    );
  }

  void _onCoinTypeSelect(
    CoinsManagerCoinTypeSelect event,
    Emitter<CoinsManagerState> emit,
  ) {
    final List<CoinType> newTypes = state.selectedCoinTypes.contains(event.type)
        ? state.selectedCoinTypes.where((type) => type != event.type).toList()
        : [...state.selectedCoinTypes, event.type];

    emit(state.copyWith(selectedCoinTypes: newTypes));

    add(CoinsManagerCoinsUpdate(state.action));
  }

  Future<void> _onCoinsSwitch(
    CoinsManagerCoinsSwitch event,
    Emitter<CoinsManagerState> emit,
  ) async {
    final List<Coin> selectedCoins = [...state.selectedCoins];
    emit(state.copyWith(isSwitching: true));

    final Future<void> switchingFuture = state.action == CoinsManagerAction.add
        ? _coinsRepo.activateCoinsSync(selectedCoins)
        : _coinsRepo.deactivateCoinsSync(selectedCoins);

    emit(state.copyWith(selectedCoins: [], isSwitching: false));
    await switchingFuture;
  }

  Future<void> _onCoinSelect(
    CoinsManagerCoinSelect event,
    Emitter<CoinsManagerState> emit,
  ) async {
    final coin = event.coin;
    final Set<Coin> selectedCoins = Set.from(state.selectedCoins);
    final bool wasSelected = selectedCoins.contains(coin);

    // Check if this is a deselection (removal) that needs trading checks
    final bool isDeselection = wasSelected;
    final bool needsTradingChecks =
        isDeselection && state.action == CoinsManagerAction.add;

    if (needsTradingChecks) {
      // Trigger the same removal flow as the remove action
      add(CoinsManagerCoinRemoveRequested(coin: coin));
      return;
    }

    if (selectedCoins.contains(coin)) {
      selectedCoins.remove(coin);
    } else {
      selectedCoins.add(coin);
    }

    // Emit state immediately for responsive UI
    // before performing the actual activation/deactivation in background
    emit(state.copyWith(selectedCoins: selectedCoins.toList()));

    final bool shouldActivate =
        (state.action == CoinsManagerAction.add && !wasSelected) ||
            (state.action == CoinsManagerAction.remove && wasSelected);

    if (shouldActivate) {
      await _tryActivateCoin(event, coin);
    } else {
      await _tryDeactivateCoin(event, coin);
    }
  }

  Future<void> _tryDeactivateCoin(
      CoinsManagerCoinSelect event, Coin coin) async {
    try {
      await _coinsRepo.deactivateCoinsSync([event.coin]);
    } catch (e, s) {
      _log.warning('Failed to deactivate coin ${coin.abbr}', e, s);
    }
    _analyticsBloc.logEvent(
      AssetDisabledEventData(
        assetSymbol: coin.abbr,
        assetNetwork: coin.protocolType,
        walletType:
            (await _sdk.auth.currentUser)?.wallet.config.type.name ?? '',
      ),
    );
  }

  Future<void> _tryActivateCoin(CoinsManagerCoinSelect event, Coin coin) async {
    try {
      await _coinsRepo.activateCoinsSync([event.coin]);
    } catch (e, s) {
      _log.warning('Failed to activate coin ${coin.abbr}', e, s);
    }
    _analyticsBloc.logEvent(
      AssetEnabledEventData(
        assetSymbol: coin.abbr,
        assetNetwork: coin.protocolType,
        walletType:
            (await _sdk.auth.currentUser)?.wallet.config.type.name ?? '',
      ),
    );
  }

  FutureOr<void> _onSelectAll(
    CoinsManagerSelectAllTap event,
    Emitter<CoinsManagerState> emit,
  ) {
    final selectedCoins =
        state.isSelectedAllCoinsEnabled ? <Coin>[] : state.coins;
    emit(state.copyWith(selectedCoins: selectedCoins));
  }

  FutureOr<void> _onSelectedTypesReset(
    CoinsManagerSelectedTypesReset event,
    Emitter<CoinsManagerState> emit,
  ) {
    emit(state.copyWith(selectedCoinTypes: []));
    add(CoinsManagerCoinsUpdate(state.action));
  }

  FutureOr<void> _onSearchUpdate(
    CoinsManagerSearchUpdate event,
    Emitter<CoinsManagerState> emit,
  ) {
    emit(state.copyWith(searchPhrase: event.text));
    add(CoinsManagerCoinsUpdate(state.action));
  }

  FutureOr<void> _onSortChanged(
    CoinsManagerSortChanged event,
    Emitter<CoinsManagerState> emit,
  ) {
    final List<Coin> sorted =
        _sortCoins([...state.coins], state.action, event.sortData);
    emit(state.copyWith(coins: sorted, sortData: event.sortData));
  }

  Future<List<Coin>> _filterTestCoinsIfNeeded(List<Coin> coins) async {
    final settings = await _settingsRepository.loadSettings();
    return settings.testCoinsEnabled ? coins : removeTestCoins(coins);
  }

  List<Coin> _filterByPhrase(List<Coin> coins) {
    final String filter = state.searchPhrase.toLowerCase();
    final List<Coin> filtered = filter.isEmpty
        ? coins
        : coins.where((Coin coin) => compareCoinByPhrase(coin, filter)).toList()
      ..sort((a, b) => a.abbr.toLowerCase().compareTo(b.abbr.toLowerCase()));
    return filtered;
  }

  List<Coin> _filterByType(List<Coin> coins) {
    return coins
        .where((coin) => state.selectedCoinTypes.contains(coin.type))
        .toList();
  }

  /// Merges wallet coins into selected coins list when in add mode
  Future<List<Coin>> _mergeWalletCoinsIfNeeded(
    List<Coin> selectedCoins,
    CoinsManagerAction action,
  ) async {
    if (action != CoinsManagerAction.add) {
      return selectedCoins;
    }

    final walletCoins = await _coinsRepo.getWalletCoins();
    final result = List<Coin>.from(selectedCoins);
    final selectedCoinIds = result.map((c) => c.id.id).toSet();

    for (final walletCoin in walletCoins) {
      if (!selectedCoinIds.contains(walletCoin.id.id)) {
        result.add(walletCoin);
      }
    }

    return result;
  }

  List<Coin> mergeCoinLists(List<Coin> originalList, List<Coin> newList) {
    final Map<String, Coin> coinMap = {};

    for (final Coin coin in originalList) {
      coinMap[coin.id.id] = coin;
    }

    for (final Coin coin in newList) {
      coinMap[coin.id.id] = coin;
    }

    final list = coinMap.values.toList();
    return list;
  }

  List<Coin> _sortCoins(
    List<Coin> coins,
    CoinsManagerAction action,
    CoinsManagerSortData sortData,
  ) {
    List<Coin> sorted = List.from(coins);
    switch (sortData.sortType) {
      case CoinsManagerSortType.name:
        sorted = sortByName(sorted, sortData.sortDirection);
      case CoinsManagerSortType.protocol:
        sorted = sortByProtocol(sorted, sortData.sortDirection);
      case CoinsManagerSortType.balance:
        sorted = sortByUsdBalance(sorted, sortData.sortDirection, _sdk);
      case CoinsManagerSortType.none:
        sorted = sortByPriorityAndBalance(sorted, _sdk);
    }

    return sorted;
  }

  Future<void> _onCoinRemoveRequested(
    CoinsManagerCoinRemoveRequested event,
    Emitter<CoinsManagerState> emit,
  ) async {
    final coin = event.coin;

    // Find child coins (tokens)
    final walletCoins = await _coinsRepo.getWalletCoins();
    final childCoins =
        walletCoins.where((c) => c.parentCoin?.abbr == coin.abbr).toList();

    // Check for active swaps
    final hasSwap = _tradingEntitiesBloc.hasActiveSwap(coin.abbr) ||
        childCoins.any((c) => _tradingEntitiesBloc.hasActiveSwap(c.abbr));

    if (hasSwap) {
      emit(state.copyWith(
        removalState: CoinRemovalState(
          coin: coin,
          childCoins: childCoins,
          blockReason: CoinRemovalBlockReason.activeSwap,
          openOrdersCount: 0,
        ),
      ));
      return;
    }

    // Check for open orders
    final int openOrders = _tradingEntitiesBloc.openOrdersCount(coin.abbr) +
        childCoins.fold<int>(
            0, (sum, c) => sum + _tradingEntitiesBloc.openOrdersCount(c.abbr));

    if (openOrders > 0) {
      emit(state.copyWith(
        removalState: CoinRemovalState(
          coin: coin,
          childCoins: childCoins,
          blockReason: CoinRemovalBlockReason.openOrders,
          openOrdersCount: openOrders,
        ),
      ));
      return;
    }

    // No blocking conditions, proceed with confirmation flow
    emit(state.copyWith(
      removalState: CoinRemovalState(
        coin: coin,
        childCoins: childCoins,
        blockReason: CoinRemovalBlockReason.none,
        openOrdersCount: 0,
      ),
    ));
  }

  Future<void> _onCoinRemoveConfirmed(
    CoinsManagerCoinRemoveConfirmed event,
    Emitter<CoinsManagerState> emit,
  ) async {
    final removalState = state.removalState;
    if (removalState == null) return;

    final coin = removalState.coin;
    final childCoins = removalState.childCoins;

    // Cancel orders if there were any
    if (removalState.hasOpenOrders) {
      try {
        await _tradingEntitiesBloc.cancelOrdersForCoin(coin.abbr);
        for (final child in childCoins) {
          await _tradingEntitiesBloc.cancelOrdersForCoin(child.abbr);
        }
      } catch (e, s) {
        _log.warning('Failed to cancel orders for coin ${coin.abbr}', e, s);

        // Clear removal state and emit error message
        emit(state.copyWith(
          removalState: null,
          errorMessage:
              'Failed to cancel open orders for ${coin.abbr}. Please try again.',
        ));
        return;
      }
    }

    // Remove coin from selected coins if in add mode (deselection)
    // or proceed with actual removal if in remove mode
    if (state.action == CoinsManagerAction.add) {
      // Deselect the coin and all its child coins
      final selectedCoins = Set<Coin>.from(state.selectedCoins);
      selectedCoins.remove(coin);

      // Also remove all child coins from selected coins
      for (final childCoin in childCoins) {
        selectedCoins.remove(childCoin);
      }

      emit(state.copyWith(
        selectedCoins: selectedCoins.toList(),
        removalState: null,
      ));

      // Deactivate the coin
      try {
        await _tryDeactivateCoin(CoinsManagerCoinSelect(coin: coin), coin);
      } catch (e, s) {
        _log.warning(
            'Failed to deactivate coin ${coin.abbr} after removal confirmation',
            e,
            s);
        // Note: The coin is already removed from selectedCoins, so the UI state is consistent
        // even if deactivation fails
      }
    } else {
      // Clear removal state and proceed with removal via existing logic
      emit(state.copyWith(removalState: null));

      // Proceed with actual coin removal for remove mode
      add(CoinsManagerCoinSelect(coin: coin));
    }
  }

  void _onCoinRemovalCancelled(
    CoinsManagerCoinRemovalCancelled event,
    Emitter<CoinsManagerState> emit,
  ) {
    emit(state.copyWith(removalState: null));
  }

  void _onErrorCleared(
    CoinsManagerErrorCleared event,
    Emitter<CoinsManagerState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }
}

Future<List<Coin>> _getOriginalCoinList(
  CoinsRepo coinsRepo,
  CoinsManagerAction action,
) async {
  switch (action) {
    case CoinsManagerAction.add:
      return coinsRepo
          .getKnownCoinsMap(excludeExcludedAssets: true)
          .values
          .toList();
    case CoinsManagerAction.remove:
      return coinsRepo.getWalletCoins();
    case CoinsManagerAction.none:
      return [];
  }
}

typedef FilterFunction = List<Coin> Function(List<Coin>);
