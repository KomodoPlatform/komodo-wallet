import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart'
    show PubkeyInfo, KdfUser;

abstract class CoinAddressesEvent extends Equatable {
  const CoinAddressesEvent();

  @override
  List<Object?> get props => [];
}

class CoinAddressesAddressCreationSubmitted extends CoinAddressesEvent {
  const CoinAddressesAddressCreationSubmitted();
}

class CoinAddressesStarted extends CoinAddressesEvent {
  const CoinAddressesStarted();
}

class CoinAddressesSubscriptionRequested extends CoinAddressesEvent {
  const CoinAddressesSubscriptionRequested();
}

class CoinAddressesZeroBalanceVisibilityChanged extends CoinAddressesEvent {
  final bool hideZeroBalance;

  const CoinAddressesZeroBalanceVisibilityChanged(this.hideZeroBalance);

  @override
  List<Object?> get props => [hideZeroBalance];
}

/// Emitted when the pubkeys watcher emits an updated set of keys (and balances)
class CoinAddressesPubkeysUpdated extends CoinAddressesEvent {
  final List<PubkeyInfo> addresses;
  const CoinAddressesPubkeysUpdated(this.addresses);

  @override
  List<Object?> get props => [addresses];
}

/// Emitted when the pubkeys watcher reports an error
class CoinAddressesPubkeysSubscriptionFailed extends CoinAddressesEvent {
  final String error;
  const CoinAddressesPubkeysSubscriptionFailed(this.error);

  @override
  List<Object?> get props => [error];
}

/// Event triggered when auth state changes (logout/wallet switch)
class CoinAddressesAuthStateChanged extends CoinAddressesEvent {
  final KdfUser? user;

  const CoinAddressesAuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}
