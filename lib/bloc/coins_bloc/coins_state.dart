part of 'coins_bloc.dart';

class CoinsState extends Equatable {
  const CoinsState({
    required this.coins,
    required this.walletCoins,
    required this.loginActivationFinished,
    required this.pubkeys,
    required this.prices,
  });

  factory CoinsState.initial() => const CoinsState(
        coins: {},
        walletCoins: {},
        loginActivationFinished: false,
        pubkeys: {},
        prices: {},
      );

  final Map<String, Coin> coins;
  final Map<String, Coin> walletCoins;
  final bool loginActivationFinished;
  final Map<String, AssetPubkeys> pubkeys;
  final Map<String, CexPrice> prices;

  @override
  List<Object> get props =>
      [coins, walletCoins, loginActivationFinished, pubkeys, prices];

  CoinsState copyWith({
    Map<String, Coin>? coins,
    Map<String, Coin>? walletCoins,
    bool? loginActivationFinished,
    Map<String, AssetPubkeys>? pubkeys,
    Map<String, CexPrice>? prices,
  }) {
    final walletCoinsWithoutExcludedCoins = walletCoins ?? this.walletCoins
      ..removeWhere((coinId, _) => excludedAssetList.contains(coinId));
    final coinsWithoutExcludedCoins = coins ?? this.coins
      ..removeWhere((coinId, _) => excludedAssetList.contains(coinId));

    return CoinsState(
      coins: coinsWithoutExcludedCoins,
      walletCoins: walletCoinsWithoutExcludedCoins,
      loginActivationFinished:
          loginActivationFinished ?? this.loginActivationFinished,
      pubkeys: pubkeys ?? this.pubkeys,
      prices: prices ?? this.prices,
    );
  }

  /// Gets the price for a given asset ID
  CexPrice? getPriceForAsset(AssetId assetId) {
    return prices[assetId.symbol.configSymbol.toUpperCase()];
  }

  /// Gets the 24h price change percentage for a given asset ID
  double? get24hChangeForAsset(AssetId assetId) {
    return getPriceForAsset(assetId)?.change24h;
  }

  /// Calculates the USD price for a given amount of a coin
  ///
  /// [amount] The amount of the coin as a string
  /// [coinAbbr] The abbreviation/symbol of the coin
  ///
  /// Returns null if:
  /// - The coin is not found in the state
  /// - The amount cannot be parsed to a double
  /// - The coin does not have a USD price
  ///
  /// Note: This will be migrated to use the SDK's price functionality in the future.
  /// See the MarketDataManager in the SDK for the new implementation.
  @Deprecated('Use sdk.prices.fiatPrice(assetId) * amount instead')
  double? getUsdPriceByAmount(String amount, String coinAbbr) {
    final Coin? coin = coins[coinAbbr];
    final double? parsedAmount = double.tryParse(amount);
    final CexPrice? cexPrice = prices[coinAbbr.toUpperCase()];
    final double? usdPrice = cexPrice?.price;

    if (coin == null || usdPrice == null || parsedAmount == null) {
      return null;
    }
    return parsedAmount * usdPrice;
  }
}
