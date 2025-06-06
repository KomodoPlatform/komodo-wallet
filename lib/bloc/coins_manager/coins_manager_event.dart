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
