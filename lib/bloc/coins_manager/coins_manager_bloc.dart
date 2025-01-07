import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Bloc, Emitter;
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/state/wallet_state.dart';

part 'coins_manager_event.dart';
part 'coins_manager_state.dart';

class CoinsManagerBloc extends Bloc<CoinsManagerEvent, CoinsManagerState> {
  CoinsManagerBloc({
    required CoinsRepo coinsRepo,
    required CoinsManagerAction action,
    required CurrentWalletBloc currentWalletBloc,
  })  : _coinsRepo = coinsRepo,
        _currentWalletBloc = currentWalletBloc,
        super(CoinsManagerState.initial(action: action, coins: [])) {
    on<CoinsManagerCoinsUpdate>(_onCoinsUpdate);
    on<CoinsManagerCoinTypeSelect>(_onCoinTypeSelect);
    on<CoinsManagerCoinsSwitch>(_onCoinsSwitch);
    on<CoinsManagerCoinSelect>(_onCoinSelect);
    on<CoinsManagerSelectAllTap>(_onSelectAll);
    on<CoinsManagerSelectedTypesReset>(_onSelectedTypesReset);
    on<CoinsManagerSearchUpdate>(_onSearchUpdate);
  }

  final CoinsRepo _coinsRepo;
  final CurrentWalletBloc _currentWalletBloc;

  List<Coin> mergeCoinLists(List<Coin> originalList, List<Coin> newList) {
    Map<String, Coin> coinMap = {};

    for (Coin coin in originalList) {
      coinMap[coin.abbr] = coin;
    }

    for (Coin coin in newList) {
      coinMap[coin.abbr] = coin;
    }

    final list = coinMap.values.toList();
    list.sort((a, b) => a.abbr.compareTo(b.abbr));

    return list;
  }

  Future<void> _onCoinsUpdate(
    CoinsManagerCoinsUpdate event,
    Emitter<CoinsManagerState> emit,
  ) async {
    final List<FilterFunction> filters = [];

    List<Coin> list = mergeCoinLists(
      await _getOriginalCoinList(_coinsRepo, state.action, _currentWalletBloc),
      state.coins,
    );

    if (state.searchPhrase.isNotEmpty) {
      filters.add(_filterByPhrase);
    }
    if (state.selectedCoinTypes.isNotEmpty) {
      filters.add(_filterByType);
    }

    for (var filter in filters) {
      list = filter(list);
    }

    emit(state.copyWith(coins: list));
  }

  void _onCoinTypeSelect(
    CoinsManagerCoinTypeSelect event,
    Emitter<CoinsManagerState> emit,
  ) {
    final List<CoinType> newTypes = state.selectedCoinTypes.contains(event.type)
        ? state.selectedCoinTypes.where((type) => type != event.type).toList()
        : [...state.selectedCoinTypes, event.type];

    emit(state.copyWith(selectedCoinTypes: newTypes));

    add(const CoinsManagerCoinsUpdate());
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

  void _onCoinSelect(
    CoinsManagerCoinSelect event,
    Emitter<CoinsManagerState> emit,
  ) {
    final coin = event.coin;
    final List<Coin> selectedCoins = List.from(state.selectedCoins);
    if (selectedCoins.contains(coin)) {
      selectedCoins.remove(coin);

      if (state.action == CoinsManagerAction.add) {
        _coinsRepo.deactivateCoinsSync([event.coin]);
      } else {
        _coinsRepo.activateCoinsSync([event.coin]);
      }
    } else {
      selectedCoins.add(coin);

      if (state.action == CoinsManagerAction.add) {
        _coinsRepo.activateCoinsSync([event.coin]);
      } else {
        _coinsRepo.deactivateCoinsSync([event.coin]);
      }
    }
    emit(state.copyWith(selectedCoins: selectedCoins));
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
    add(const CoinsManagerCoinsUpdate());
  }

  FutureOr<void> _onSearchUpdate(
    CoinsManagerSearchUpdate event,
    Emitter<CoinsManagerState> emit,
  ) {
    emit(state.copyWith(searchPhrase: event.text));
    add(const CoinsManagerCoinsUpdate());
  }

  List<Coin> _filterByPhrase(List<Coin> coins) {
    final String filter = state.searchPhrase.toLowerCase();
    final List<Coin> filtered = filter.isEmpty
        ? coins
        : coins
            .where(
              (Coin coin) =>
                  compareCoinByPhrase(coin, filter) ||
                  state.selectedCoins.indexWhere(
                        (selectedCoin) => selectedCoin.abbr == coin.abbr,
                      ) !=
                      -1,
            )
            .toList();

    filtered
        .sort((a, b) => a.abbr.toLowerCase().compareTo(b.abbr.toLowerCase()));
    return filtered;
  }

  List<Coin> _filterByType(List<Coin> coins) {
    return coins
        .where(
          (coin) =>
              state.selectedCoinTypes.contains(coin.type) ||
              state.selectedCoins.indexWhere(
                    (selectedCoin) => selectedCoin.abbr == coin.abbr,
                  ) !=
                  -1,
        )
        .toList();
  }
}

Future<List<Coin>> _getOriginalCoinList(
  CoinsRepo coinsRepo,
  CoinsManagerAction action,
  CurrentWalletBloc currentWalletBloc,
) async {
  final WalletType? walletType = currentWalletBloc.wallet?.config.type;
  if (walletType == null) return [];

  switch (action) {
    case CoinsManagerAction.add:
      return await _getDeactivatedCoins(coinsRepo, walletType);
    case CoinsManagerAction.remove:
      return await _getActivatedCoins(coinsRepo);
    case CoinsManagerAction.none:
      return [];
  }
}

Future<List<Coin>> _getActivatedCoins(CoinsRepo coinsRepo) async {
  return (await coinsRepo.getEnabledCoins())
      .where((coin) => !coin.isActivating)
      .toList();
}

Future<List<Coin>> _getDeactivatedCoins(
  CoinsRepo coinsRepo,
  WalletType walletType,
) async {
  final Map<String, Coin> enabledCoins = await coinsRepo.getEnabledCoinsMap();
  final Map<String, Coin> disabledCoins = (coinsRepo.getKnownCoinsMap())
    ..removeWhere((key, coin) => enabledCoins.containsKey(key));

  switch (walletType) {
    case WalletType.iguana:
      return disabledCoins.values.toList();
    case WalletType.trezor:
      final disabledCoinsWithTrezorSupport =
          disabledCoins.values.where((coin) => coin.hasTrezorSupport);
      return disabledCoinsWithTrezorSupport.toList();
    case WalletType.metamask:
    case WalletType.keplr:
      return [];
  }
}

typedef FilterFunction = List<Coin> Function(List<Coin>);
