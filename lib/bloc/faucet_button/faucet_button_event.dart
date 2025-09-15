import 'package:equatable/equatable.dart';

abstract class FaucetEvent extends Equatable {
  const FaucetEvent();

  @override
  List<Object> get props => [];
}

class FaucetRequested extends FaucetEvent {
  final String coinAbbr;
  final String address;

  const FaucetRequested({required this.coinAbbr, required this.address});

  @override
  List<Object> get props => [coinAbbr, address];
}
