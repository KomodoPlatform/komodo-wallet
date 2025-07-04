import 'package:equatable/equatable.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/get_new_address/get_new_address_response.dart';

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

class AddressStatusUpdated extends CoinAddressesEvent {
  final GetNewAddressResponse status;

  const AddressStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}
