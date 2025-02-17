import 'package:equatable/equatable.dart';

abstract class CoinAddressesEvent extends Equatable {
  const CoinAddressesEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCreateAddressEvent extends CoinAddressesEvent {
  const SubmitCreateAddressEvent();
}

class LoadAddressesEvent extends CoinAddressesEvent {
  const LoadAddressesEvent();
}

class UpdateHideZeroBalanceEvent extends CoinAddressesEvent {
  final bool hideZeroBalance;

  const UpdateHideZeroBalanceEvent(this.hideZeroBalance);

  @override
  List<Object?> get props => [hideZeroBalance];
}
