import 'package:equatable/equatable.dart';
import 'package:web_dex/model/coin_type.dart';

abstract class CustomTokenImportEvent extends Equatable {
  const CustomTokenImportEvent();

  @override
  List<Object?> get props => [];
}

class UpdateNetworkEvent extends CustomTokenImportEvent {
  final CoinType? network;

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

class UpdateDecimalsEvent extends CustomTokenImportEvent {
  final int? decimals;

  const UpdateDecimalsEvent(this.decimals);

  @override
  List<Object?> get props => [decimals];
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
