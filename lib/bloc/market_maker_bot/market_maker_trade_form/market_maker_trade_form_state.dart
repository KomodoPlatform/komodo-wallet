part of 'market_maker_trade_form_bloc.dart';

enum MarketMakerTradeFormError {
  insufficientBalanceBase,
  insufficientBalanceRel,
  insufficientBalanceRelParent,
  insufficientTradeAmount,
  none,
}

enum MarketMakerTradeFormStatus { initial, loading, success, error }

// Usually this would be a dedicated tab contoller/ui flow bloc, but because
// there is only two stages (initial and confirmationRequired), and for the
// sake of simplicity, we are using the form state to manage the form stages.
enum MarketMakerTradeFormStage {
  initial,
  confirmationRequired,
}

/// The state of the market maker trade form. The state is a formz mixin
/// which allows the form to be validated and checked for errors.
class MarketMakerTradeFormState extends Equatable with FormzMixin {
  const MarketMakerTradeFormState({
    required this.sellCoin,
    required this.buyCoin,
    required this.minimumTradeVolume,
    required this.maximumTradeVolume,
    required this.sellAmount,
    required this.buyAmount,
    required this.tradeMargin,
    required this.updateInterval,
    required this.status,
    required this.stage,
    this.tradePreImageError,
    this.tradePreImage,
  });

  MarketMakerTradeFormState.initial()
      : sellCoin = const CoinSelectInput.pure(),
        buyCoin = const CoinSelectInput.pure(),
        minimumTradeVolume = const TradeVolumeInput.pure(0.1),
        maximumTradeVolume = const TradeVolumeInput.pure(0.9),
        sellAmount = const CoinTradeAmountInput.pure(),
        buyAmount = const CoinTradeAmountInput.pure(),
        tradeMargin = const TradeMarginInput.pure(),
        updateInterval = const UpdateIntervalInput.pure(),
        status = MarketMakerTradeFormStatus.initial,
        stage = MarketMakerTradeFormStage.initial,
        tradePreImageError = null,
        tradePreImage = null;

  /// The coin being sold in the trade pair (base coin).
  final CoinSelectInput sellCoin;

  /// The coin being bought in the trade pair (rel coin).
  final CoinSelectInput buyCoin;

  /// The minimum volume to use per trade. E.g. The minimum trade volume in USD.
  final TradeVolumeInput minimumTradeVolume;

  /// The maximum volume to use per trade.
  /// E.g. The maximum trade volume in percentage.
  final TradeVolumeInput maximumTradeVolume;

  /// The amount of the base coin being sold.
  final CoinTradeAmountInput sellAmount;

  /// The amount of the rel coin being bought.
  final CoinTradeAmountInput buyAmount;

  /// The trade margin percentage over the usd market price (cex rate).
  final TradeMarginInput tradeMargin;

  /// The interval at which the market maker bot should update the trade pair.
  /// The interval is in seconds.
  final UpdateIntervalInput updateInterval;

  /// Whether the form is in the initial, in progress, success or error state.
  final MarketMakerTradeFormStatus status;

  /// The error state of the form.
  final MarketMakerTradeFormError? tradePreImageError;

  /// The current stage of the form (confirmation or initial).
  final MarketMakerTradeFormStage stage;

  /// The preimage of the trade pair, used to calculate the trade pair fees.
  final TradePreimage? tradePreImage;

  /// The price of the trade pair derived from the USD price of the coins.
  /// Price = baseCoinUsdPrice / relCoinUsdPrice.
  double? get priceFromUsd {
    final baseUsdPrice = sellCoin.value?.usdPrice?.price;
    final relUsdPrice = buyCoin.value?.usdPrice?.price;
    final price = relUsdPrice != null && baseUsdPrice != null
        ? baseUsdPrice / relUsdPrice
        : null;

    return price?.toDouble();
  }

  /// The price of the trade pair derived from the USD price of the coins
  /// with the trade margin applied. The trade margin is a percentage over
  /// the usd market price (cex rate).
  double? get priceFromUsdWithMargin {
    final price = priceFromUsd;
    final spreadPercentage = double.tryParse(tradeMargin.value) ?? 0;
    if (price != null) {
      return price * (1 + (spreadPercentage / 100));
    }
    return price;
  }

  /// The price of the trade pair derived from the USD price of the coins
  /// with the trade margin applied. The trade margin is a percentage over
  /// the usd market price (cex rate).
  Rational? get priceFromUsdWithMarginRational {
    final price = priceFromUsdWithMargin;
    return price != null ? Rational.parse(price.toString()) : null;
  }

  /// The price of the trade pair derived from the amount of the coins.
  /// Price = buyAmount / sellAmount.
  double get priceFromAmount {
    final sellAmount = double.tryParse(this.sellAmount.value) ?? 0;
    final buyAmount = double.tryParse(this.buyAmount.value) ?? 0;
    return sellAmount != 0 ? buyAmount / sellAmount : 0;
  }

  /// The margin percentage derived from the amount of the coins.
  /// Margin = (priceFromAmount / priceFromUsd - 1) * 100.
  double get marginFromAmounts {
    double newMargin = tradeMargin.valueAsDouble;
    if (sellAmount.value.isEmpty) {
      return newMargin;
    }

    final currentPrice = priceFromUsd;
    if (currentPrice == null || currentPrice == 0) {
      return newMargin;
    }

    final amountPrice = priceFromAmount;
    if (currentPrice == amountPrice) {
      return newMargin;
    }

    newMargin = (amountPrice / currentPrice - 1) * 100;
    return newMargin;
  }

  MarketMakerTradeFormState copyWith({
    CoinSelectInput? sellCoin,
    CoinSelectInput? buyCoin,
    TradeVolumeInput? minimumTradeVolume,
    TradeVolumeInput? maximumTradeVolume,
    CoinTradeAmountInput? sellAmount,
    CoinTradeAmountInput? buyAmount,
    TradeMarginInput? tradeMargin,
    UpdateIntervalInput? updateInterval,
    MarketMakerTradeFormStatus? status,
    MarketMakerTradeFormError? preImageError,
    MarketMakerTradeFormStage? stage,
    TradePreimage? tradePreImage,
  }) {
    return MarketMakerTradeFormState(
      sellCoin: sellCoin ?? this.sellCoin,
      buyCoin: buyCoin ?? this.buyCoin,
      minimumTradeVolume: minimumTradeVolume ?? this.minimumTradeVolume,
      maximumTradeVolume: maximumTradeVolume ?? this.maximumTradeVolume,
      sellAmount: sellAmount ?? this.sellAmount,
      buyAmount: buyAmount ?? this.buyAmount,
      tradeMargin: tradeMargin ?? this.tradeMargin,
      updateInterval: updateInterval ?? this.updateInterval,
      status: status ?? this.status,
      tradePreImageError: preImageError,
      stage: stage ?? this.stage,
      tradePreImage: tradePreImage ?? this.tradePreImage,
    );
  }

  /// Converts the form state to a [TradeCoinPairConfig] object to be used
  /// in the market maker bot parameters.
  TradeCoinPairConfig toTradePairConfig() {
    final baseCoinId = sellCoin.value?.abbr ?? '';
    final relCoinId = buyCoin.value?.abbr ?? '';
    final spreadPercentage = double.parse(tradeMargin.value);
    final spread = 1 + (spreadPercentage / 100);

    return TradeCoinPairConfig(
      name: TradeCoinPairConfig.getSimpleName(baseCoinId, relCoinId),
      baseCoinId: baseCoinId,
      relCoinId: relCoinId,
      spread: spread.toString(),
      priceElapsedValidity: updateInterval.interval.seconds,
      maxVolume: TradeVolume.percentage(maximumTradeVolume.value),
      minVolume: TradeVolume.percentage(minimumTradeVolume.value),
    );
  }

  @override
  List<FormzInput<dynamic, dynamic>> get inputs => [
        sellCoin,
        buyCoin,
        minimumTradeVolume,
        maximumTradeVolume,
        tradeMargin,
        updateInterval,
      ];

  @override
  bool get isValid {
    return super.isValid &&
        tradePreImageError == null &&
        status != MarketMakerTradeFormStatus.error;
  }

  @override
  List<Object?> get props => [
        sellCoin,
        buyCoin,
        minimumTradeVolume,
        maximumTradeVolume,
        sellAmount,
        buyAmount,
        tradeMargin,
        updateInterval,
        tradePreImageError,
        stage,
        status,
        tradePreImage,
      ];
}
