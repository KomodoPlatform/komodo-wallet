part of 'nft_receive_bloc.dart';

abstract class NftReceiveEvent extends Equatable {
  const NftReceiveEvent();

  @override
  List<Object?> get props => [];
}

class NftReceiveStarted extends NftReceiveEvent {
  const NftReceiveStarted({required this.chain});

  final NftBlockchains chain;

  @override
  List<Object> get props => [chain];
}

class NftReceiveRefreshRequested extends NftReceiveEvent {
  const NftReceiveRefreshRequested();

  @override
  List<Object> get props => [];
}

class NftReceiveAddressChanged extends NftReceiveEvent {
  const NftReceiveAddressChanged({required this.address});

  final PubkeyInfo? address;

  @override
  List<Object?> get props => [address];
}
