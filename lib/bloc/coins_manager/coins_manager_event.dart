part of 'coins_manager_bloc.dart';

abstract class CoinsManagerEvent {
  const CoinsManagerEvent();
}

class CoinsManagerCoinsListReset extends CoinsManagerEvent {
  const CoinsManagerCoinsListReset(this.action);
  final CoinsManagerAction action;
}

class CoinsManagerCoinsUpdate extends CoinsManagerEvent {
  const CoinsManagerCoinsUpdate(this.action);
  final CoinsManagerAction action;
}

class CoinsManagerCoinTypeSelect extends CoinsManagerEvent {
  const CoinsManagerCoinTypeSelect({required this.type});
  final CoinType type;
}

class CoinsManagerCoinsSwitch extends CoinsManagerEvent {
  @Deprecated('Switching between add and remove assets was removed, '
      'so this event and its UI references are no longer used.')
  const CoinsManagerCoinsSwitch();
}

class CoinsManagerCoinSelect extends CoinsManagerEvent {
  const CoinsManagerCoinSelect({required this.coin});
  final Coin coin;
}

class CoinsManagerSelectAllTap extends CoinsManagerEvent {
  const CoinsManagerSelectAllTap();
}

class CoinsManagerSelectedTypesReset extends CoinsManagerEvent {
  const CoinsManagerSelectedTypesReset();
}

class CoinsManagerSearchUpdate extends CoinsManagerEvent {
  const CoinsManagerSearchUpdate({required this.text});
  final String text;
}

class CoinsManagerSortChanged extends CoinsManagerEvent {
  const CoinsManagerSortChanged(this.sortData);

  final CoinsManagerSortData sortData;
}

class CoinsManagerCoinRemoveRequested extends CoinsManagerEvent {
  const CoinsManagerCoinRemoveRequested({required this.coin});
  final Coin coin;
}

class CoinsManagerCoinRemoveConfirmed extends CoinsManagerEvent {
  const CoinsManagerCoinRemoveConfirmed();
}

class CoinsManagerCoinRemovalCancelled extends CoinsManagerEvent {
  const CoinsManagerCoinRemovalCancelled();
}

class CoinsManagerErrorCleared extends CoinsManagerEvent {
  const CoinsManagerErrorCleared();
}
