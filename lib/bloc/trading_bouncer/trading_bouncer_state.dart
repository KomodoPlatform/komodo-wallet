import 'package:equatable/equatable.dart';
import 'package:web_dex/app_config/app_config.dart';

class TradingBouncerState extends Equatable {
  const TradingBouncerState({required this.walletOnly});

  factory TradingBouncerState.initial() {
    return TradingBouncerState(walletOnly: kIsWalletOnly);
  }

  final bool walletOnly;

  @override
  List<Object?> get props => [walletOnly];

  TradingBouncerState copyWith({bool? walletOnly}) {
    return TradingBouncerState(walletOnly: walletOnly ?? this.walletOnly);
  }
}
