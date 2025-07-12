import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Bloc, Emitter;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/analytics/events/portfolio_events.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/model/kdf_auth_metadata_extension.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/state/wallet_state.dart';

part 'coins_manager_event.dart';
part 'coins_manager_state.dart';

class CoinsManagerBloc extends Bloc<CoinsManagerEvent, CoinsManagerState> {
  CoinsManagerBloc({
    required CoinsRepo coinsRepo,
    required KomodoDefiSdk sdk,
    required AnalyticsBloc analyticsBloc,
  })  : _coinsRepo = coinsRepo,
        _sdk = sdk,
        _analyticsBloc = analyticsBloc,
        super(CoinsManagerState.initial(coins: [])) {
    on<CoinsManagerCoinsUpdate>(_onCoinsUpdate);
    on<CoinsManagerCoinsListReset>(_onCoinsListReset);
    on<CoinsManagerCoinTypeSelect>(_onCoinTypeSelect);
    on<CoinsManagerCoinsSwitch>(_onCoinsSwitch);
    on<CoinsManagerCoinSelect>(_onCoinSelect);
    on<CoinsManagerSelectAllTap>(_onSelectAll);
    on<CoinsManagerSelectedTypesReset>(_onSelectedTypesReset);
    on<CoinsManagerSearchUpdate>(_onSearchUpdate);
  }

  final CoinsRepo _coinsRepo;
  final KomodoDefiSdk _sdk;
  final AnalyticsBloc _analyticsBloc;

  List<Coin> mergeCoinLists(List<Coin> originalList, List<Coin> newList) {
    final Map<String, Coin> coinMap = {};

    for (final Coin coin in originalList) {
      coinMap[coin.abbr] = coin;
    }

    for (final Coin coin in newList) {
      coinMap[coin.abbr] = coin;
    }

    final list = coinMap.values.toList()
      ..sort((a, b) => a.abbr.compareTo(b.abbr));

    return list;
  }

  Future<void> _onCoinsUpdate(
    CoinsManagerCoinsUpdate event,
    Emitter<CoinsManagerState> emit,
  ) async {
    final List<FilterFunction> filters = [];

    List<Coin> list = mergeCoinLists(
      await _getOriginalCoinList(_coinsRepo, event.action, _sdk),
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

    emit(state.copyWith(coins: list, action: event.action));
  }

  Future<void> _onCoinsListReset(
    CoinsManagerCoinsListReset event,
    Emitter<CoinsManagerState> emit,
  ) async {
    emit(CoinsManagerState.initial(coins: [], action: event.action));
    final List<Coin> coins = await _getOriginalCoinList(
      _coinsRepo,
      event.action,
      _sdk,
    )
      ..sort((a, b) => a.abbr.compareTo(b.abbr));
    emit(state.copyWith(coins: coins, action: event.action));
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
    final List<Coin> selectedCoins = List.from(state.selectedCoins);
    if (selectedCoins.contains(coin)) {
      selectedCoins.remove(coin);

      if (state.action == CoinsManagerAction.add) {
        _coinsRepo.deactivateCoinsSync([event.coin]);
        _analyticsBloc.logEvent(
          AssetDisabledEventData(
            assetSymbol: coin.abbr,
            assetNetwork: coin.protocolType,
            walletType:
                (await _sdk.auth.currentUser)?.wallet.config.type.name ?? '',
          ),
        );
      } else {
        _coinsRepo.activateCoinsSync([event.coin]);
        _analyticsBloc.logEvent(
          AssetEnabledEventData(
            assetSymbol: coin.abbr,
            assetNetwork: coin.protocolType,
            walletType:
                (await _sdk.auth.currentUser)?.wallet.config.type.name ?? '',
          ),
        );
      }
    } else {
      selectedCoins.add(coin);

      if (state.action == CoinsManagerAction.add) {
        _coinsRepo.activateCoinsSync([event.coin]);
        _analyticsBloc.logEvent(
          AssetEnabledEventData(
            assetSymbol: coin.abbr,
            assetNetwork: coin.protocolType,
            walletType:
                (await _sdk.auth.currentUser)?.wallet.config.type.name ?? '',
          ),
        );
      } else {
        _coinsRepo.deactivateCoinsSync([event.coin]);
        _analyticsBloc.logEvent(
          AssetDisabledEventData(
            assetSymbol: coin.abbr,
            assetNetwork: coin.protocolType,
            walletType:
                (await _sdk.auth.currentUser)?.wallet.config.type.name ?? '',
          ),
        );
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
    add(CoinsManagerCoinsUpdate(state.action));
  }

  FutureOr<void> _onSearchUpdate(
    CoinsManagerSearchUpdate event,
    Emitter<CoinsManagerState> emit,
  ) {
    emit(state.copyWith(searchPhrase: event.text));
    add(CoinsManagerCoinsUpdate(state.action));
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
  KomodoDefiSdk sdk,
) async {
  final WalletType? walletType = (await sdk.currentWallet())?.config.type;
  if (walletType == null) return [];

  switch (action) {
    case CoinsManagerAction.add:
      return _getDeactivatedCoins(coinsRepo, sdk, walletType);
    case CoinsManagerAction.remove:
      return coinsRepo.getWalletCoins();
    case CoinsManagerAction.none:
      return [];
  }
}

Future<List<Coin>> _getDeactivatedCoins(
  CoinsRepo coinsRepo,
  KomodoDefiSdk sdk,
  WalletType walletType,
) async {
  final Iterable<String> walletCoins =
      (await sdk.currentWallet())?.config.activatedCoins ?? [];
  final Map<String, Coin> disabledCoins = coinsRepo.getKnownCoinsMap()
    ..removeWhere((coinId, coin) => walletCoins.contains(coinId))
    ..removeWhere((coinId, coin) => excludedAssetList.contains(coinId));

  switch (walletType) {
    case WalletType.iguana:
    case WalletType.trezor:
    case WalletType.hdwallet:
      return disabledCoins.values.toList();
    case WalletType.metamask:
    case WalletType.keplr:
      return [];
  }
}

typedef FilterFunction = List<Coin> Function(List<Coin>);
