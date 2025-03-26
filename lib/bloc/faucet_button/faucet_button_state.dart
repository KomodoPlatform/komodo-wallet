import 'package:equatable/equatable.dart';
import 'package:web_dex/3p_api/faucet/faucet_response.dart';

abstract class FaucetState extends Equatable {
  const FaucetState();

  @override
  List<Object?> get props => [];
}

class FaucetInitial extends FaucetState {
  const FaucetInitial();
}

class FaucetRequestInProgress extends FaucetState {
  final String address;

  const FaucetRequestInProgress({required this.address});

  @override
  List<Object?> get props => [address];
}

class FaucetSuccess extends FaucetState {
  final FaucetResponse response;

  const FaucetSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class FaucetError extends FaucetState {
  final String message;

  const FaucetError(this.message);

  @override
  List<Object?> get props => [message];
}