import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

abstract class CustomTokenImportEvent extends Equatable {
  const CustomTokenImportEvent();

  @override
  List<Object?> get props => [];
}

class UpdateNetworkEvent extends CustomTokenImportEvent {
  final CoinSubClass? network;

  const UpdateNetworkEvent(this.network);

  @override
  List<Object?> get props => [network];
}

class UpdateAddressEvent extends CustomTokenImportEvent {
  final String address;

  const UpdateAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class SubmitImportCustomTokenEvent extends CustomTokenImportEvent {
  const SubmitImportCustomTokenEvent();
}

class SubmitFetchCustomTokenEvent extends CustomTokenImportEvent {
  const SubmitFetchCustomTokenEvent();
}

class ResetFormStatusEvent extends CustomTokenImportEvent {
  const ResetFormStatusEvent();
}
