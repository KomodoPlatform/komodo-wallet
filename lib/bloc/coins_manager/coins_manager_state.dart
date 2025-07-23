part of 'coins_manager_bloc.dart';

class CoinsManagerState extends Equatable {
  const CoinsManagerState({
    required this.action,
    required this.searchPhrase,
    required this.selectedCoinTypes,
    required this.coins,
    required this.selectedCoins,
    required this.sortData,
    required this.isSwitching,
    this.removalState,
    this.errorMessage,
  });
  final CoinsManagerAction action;
  final String searchPhrase;
  final List<CoinType> selectedCoinTypes;
  final List<Coin> coins;
  final List<Coin> selectedCoins;
  final CoinsManagerSortData sortData;
  final bool isSwitching;
  final CoinRemovalState? removalState;
  final String? errorMessage;

  static CoinsManagerState initial({
    required List<Coin> coins,
    CoinsManagerAction action = CoinsManagerAction.add,
  }) {
    return CoinsManagerState(
      action: action,
      searchPhrase: '',
      selectedCoinTypes: const [],
      coins: coins,
      selectedCoins: const [],
      sortData: const CoinsManagerSortData(
        sortDirection: SortDirection.none,
        sortType: CoinsManagerSortType.none,
      ),
      isSwitching: false,
      removalState: null,
      errorMessage: null,
    );
  }

  CoinsManagerState copyWith({
    CoinsManagerAction? action,
    String? searchPhrase,
    List<CoinType>? selectedCoinTypes,
    List<Coin>? coins,
    List<Coin>? selectedCoins,
    CoinsManagerSortData? sortData,
    bool? isSwitching,
    CoinRemovalState? removalState,
    String? errorMessage,
  }) =>
      CoinsManagerState(
        action: action ?? this.action,
        coins: coins ?? this.coins,
        searchPhrase: searchPhrase ?? this.searchPhrase,
        selectedCoinTypes: selectedCoinTypes ?? this.selectedCoinTypes,
        selectedCoins: selectedCoins ?? this.selectedCoins,
        sortData: sortData ?? this.sortData,
        isSwitching: isSwitching ?? this.isSwitching,
        removalState: removalState,
        errorMessage: errorMessage,
      );

  bool get isSelectedAllCoinsEnabled {
    if (selectedCoins.isEmpty) return false;

    return coins.every((coin) => selectedCoins.contains(coin));
  }

  @override
  List<Object?> get props => [
        action,
        searchPhrase,
        selectedCoinTypes,
        coins,
        selectedCoins,
        sortData,
        isSwitching,
        removalState,
        errorMessage,
      ];
}

enum CoinRemovalBlockReason {
  none,
  activeSwap,
  openOrders,
}

class CoinRemovalState extends Equatable {
  const CoinRemovalState({
    required this.coin,
    required this.childCoins,
    required this.blockReason,
    required this.openOrdersCount,
  });

  final Coin coin;
  final List<Coin> childCoins;
  final CoinRemovalBlockReason blockReason;
  final int openOrdersCount;

  bool get isBlocked => blockReason != CoinRemovalBlockReason.none;
  bool get hasActiveSwap => blockReason == CoinRemovalBlockReason.activeSwap;
  bool get hasOpenOrders => blockReason == CoinRemovalBlockReason.openOrders;

  @override
  List<Object?> get props => [coin, childCoins, blockReason, openOrdersCount];
}
