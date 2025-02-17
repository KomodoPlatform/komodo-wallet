part of 'coins_bloc.dart';

class CoinsState extends Equatable {
  const CoinsState({
    required this.coins,
    required this.walletCoins,
    required this.loginActivationFinished,
    required this.pubkeys,
  });

  factory CoinsState.initial() => const CoinsState(
        coins: {},
        walletCoins: {},
        loginActivationFinished: false,
        pubkeys: {},
      );

  final Map<String, Coin> coins;
  final Map<String, Coin> walletCoins;
  final bool loginActivationFinished;
  final Map<String, AssetPubkeys> pubkeys;

  @override
  List<Object> get props =>
      [coins, walletCoins, loginActivationFinished, pubkeys];

  CoinsState copyWith({
    Map<String, Coin>? coins,
    Map<String, Coin>? walletCoins,
    bool? loginActivationFinished,
    Map<String, AssetPubkeys>? pubkeys,
  }) {
    return CoinsState(
      coins: coins ?? this.coins,
      walletCoins: walletCoins ?? this.walletCoins,
      loginActivationFinished:
          loginActivationFinished ?? this.loginActivationFinished,
      pubkeys: pubkeys ?? this.pubkeys,
    );
  }

  // TODO! Migrate to SDK
  double? getUsdPriceByAmount(String amount, String coinAbbr) {
    final Coin? coin = coins[coinAbbr];
    final double? parsedAmount = double.tryParse(amount);
    final double? usdPrice = coin?.usdPrice?.price;

    if (coin == null || usdPrice == null || parsedAmount == null) {
      return null;
    }
    return parsedAmount * usdPrice;
  }
}
