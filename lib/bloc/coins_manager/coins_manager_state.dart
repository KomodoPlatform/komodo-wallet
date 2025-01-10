part of 'coins_manager_bloc.dart';

class CoinsManagerState extends Equatable {
  const CoinsManagerState({
    required this.action,
    required this.searchPhrase,
    required this.selectedCoinTypes,
    required this.coins,
    required this.selectedCoins,
    required this.isSwitching,
  });
  final CoinsManagerAction action;
  final String searchPhrase;
  final List<CoinType> selectedCoinTypes;
  final List<Coin> coins;
  final List<Coin> selectedCoins;
  final bool isSwitching;

  static CoinsManagerState initial({
    required CoinsManagerAction action,
    required List<Coin> coins,
  }) {
    return CoinsManagerState(
      action: action,
      searchPhrase: '',
      selectedCoinTypes: const [],
      coins: coins,
      selectedCoins: const [],
      isSwitching: false,
    );
  }

  CoinsManagerState copyWith({
    CoinsManagerAction? action,
    String? searchPhrase,
    List<CoinType>? selectedCoinTypes,
    List<Coin>? coins,
    List<Coin>? selectedCoins,
    bool? isSwitching,
  }) =>
      CoinsManagerState(
        action: action ?? this.action,
        coins: coins ?? this.coins,
        searchPhrase: searchPhrase ?? this.searchPhrase,
        selectedCoinTypes: selectedCoinTypes ?? this.selectedCoinTypes,
        selectedCoins: selectedCoins ?? this.selectedCoins,
        isSwitching: isSwitching ?? this.isSwitching,
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
        isSwitching,
      ];
}
