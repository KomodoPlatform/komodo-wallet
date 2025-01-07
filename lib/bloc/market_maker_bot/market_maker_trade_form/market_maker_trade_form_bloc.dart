import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/dex_repository.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/trade_pair.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/trade_coin_pair_config.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/trade_volume.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trade_preimage/trade_preimage_errors.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/data_from_service.dart';
import 'package:web_dex/model/forms/coin_select_input.dart';
import 'package:web_dex/model/forms/coin_trade_amount_input.dart';
import 'package:web_dex/model/forms/trade_margin_input.dart';
import 'package:web_dex/model/forms/trade_volume_input.dart';
import 'package:web_dex/model/forms/update_interval_input.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/model/trade_preimage.dart';

part 'market_maker_trade_form_event.dart';
part 'market_maker_trade_form_state.dart';

class MarketMakerTradeFormBloc
    extends Bloc<MarketMakerTradeFormEvent, MarketMakerTradeFormState> {
  /// The market maker trade form bloc is used to manage the state of the trade
  /// form. The trade form is used to create a trade pair for the market maker
  /// bot.
  ///
  /// The [DexRepository] is used to get the trade preimage, which is used
  /// to pre-emptively check if a trade will be successful.
  ///
  /// The [CoinsRepo] is used to activate coins that are not active when
  /// they are selected in the trade form.
  MarketMakerTradeFormBloc({
    required DexRepository dexRepo,
    required CoinsRepo coinsRepo,
  })  : _dexRepository = dexRepo,
        _coinsRepo = coinsRepo,
        super(MarketMakerTradeFormState.initial()) {
    on<MarketMakerTradeFormSellCoinChanged>(_onSellCoinChanged);
    on<MarketMakerTradeFormBuyCoinChanged>(_onBuyCoinChanged);
    on<MarketMakerTradeFormTradeVolumeChanged>(_onTradeVolumeChanged);
    on<MarketMakerTradeFormSwapCoinsRequested>(_onSwapCoinsRequested);
    on<MarketMakerTradeFormTradeMarginChanged>(_onTradeMarginChanged);
    on<MarketMakerTradeFormUpdateIntervalChanged>(_onUpdateIntervalChanged);
    on<MarketMakerTradeFormClearRequested>(_onClearForm);
    on<MarketMakerTradeFormEditOrderRequested>(_onEditOrder);
    on<MarketMakerTradeFormAskOrderbookSelected>(_onOrderbookSelected);
    on<MarketMakerConfirmationPreviewRequested>(_onPreviewConfirmation);
    on<MarketMakerConfirmationPreviewCancelRequested>(
      _onPreviewConfirmationCancelled,
    );
  }

  /// The dex repository is used to get the trade preimage, which is used
  /// to pre-emptively check if a trade will be successful
  final DexRepository _dexRepository;

  /// The coins repository is used to activate coins that are not active
  /// when they are selected in the trade form
  final CoinsRepo _coinsRepo;

  Future<void> _onSellCoinChanged(
    MarketMakerTradeFormSellCoinChanged event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    final identicalBuyAndSellCoins = state.buyCoin.value == event.sellCoin;
    final sellCoinBalance = event.sellCoin?.balance ?? 0;
    final newSellAmount = CoinTradeAmountInput.dirty(
      (state.maximumTradeVolume.value * sellCoinBalance).toString(),
    );

    emit(
      state.copyWith(
        sellCoin: CoinSelectInput.dirty(event.sellCoin),
        sellAmount: newSellAmount,
        buyCoin: identicalBuyAndSellCoins
            ? const CoinSelectInput.dirty(null, -1)
            : state.buyCoin,
        status: MarketMakerTradeFormStatus.success,
      ),
    );

    if (!identicalBuyAndSellCoins && state.buyCoin.value != null) {
      final double newBuyAmount = _getBuyAmountFromSellAmount(
        newSellAmount.value,
        state.priceFromUsdWithMargin,
      );
      emit(
        state.copyWith(
          buyAmount: CoinTradeAmountInput.dirty(newBuyAmount.toString()),
        ),
      );
    }

    await _autoActivateCoin(event.sellCoin);

    if (state.buyCoin.value != null) {
      final preImage = await _getPreimageData(state);
      final preImageError = await _getPreImageError(preImage.error, state);
      if (preImageError != MarketMakerTradeFormError.none) {
        emit(state.copyWith(preImageError: preImageError));
      }
    }
  }

  Future<void> _onBuyCoinChanged(
    MarketMakerTradeFormBuyCoinChanged event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    // Update the buy and sell coins first before calculating the buy amount
    // since the priceFromUsdWithMargin is dependent on the buy coin.
    // An alternative approach would be to calculate the new price with margin
    // here and pass that to the function, but that would require a lot of
    // code duplication and would be harder to maintain.
    final areBuyAndSellCoinsIdentical = event.buyCoin == state.sellCoin.value;
    emit(
      state.copyWith(
        buyCoin: CoinSelectInput.dirty(event.buyCoin, -1),
        sellCoin: areBuyAndSellCoinsIdentical
            ? const CoinSelectInput.dirty(null, -1)
            : state.sellCoin,
        status: MarketMakerTradeFormStatus.success,
      ),
    );

    await _autoActivateCoin(event.buyCoin);
    // Buy coin does not have to have a balance, so set the minimum balance to
    // -1 to avoid the insufficient balance error
    final newBuyAmount = _getBuyAmountFromSellAmount(
      state.sellAmount.value,
      state.priceFromUsdWithMargin,
    );

    emit(
      state.copyWith(
        buyAmount: newBuyAmount > 0
            ? CoinTradeAmountInput.dirty(newBuyAmount.toString())
            : const CoinTradeAmountInput.dirty(),
        status: MarketMakerTradeFormStatus.success,
      ),
    );

    final preImage = await _getPreimageData(state);
    final preImageError = await _getPreImageError(preImage.error, state);
    if (preImageError != MarketMakerTradeFormError.none) {
      emit(state.copyWith(preImageError: preImageError));
    }
  }

  Future<void> _onTradeVolumeChanged(
    MarketMakerTradeFormTradeVolumeChanged event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    final sellCoinBalance = state.sellCoin.value?.balance ?? 0;
    final newSellAmount = CoinTradeAmountInput.dirty(
      (event.maximumTradeVolume * sellCoinBalance).toString(),
      0,
      state.sellCoin.value!.balance,
    );
    final newBuyAmount = _getBuyAmountFromSellAmount(
      newSellAmount.value,
      state.priceFromUsdWithMargin,
    );
    emit(
      state.copyWith(
        sellAmount: newSellAmount,
        buyAmount: CoinTradeAmountInput.dirty(newBuyAmount.toString()),
        minimumTradeVolume: TradeVolumeInput.dirty(event.minimumTradeVolume),
        maximumTradeVolume: TradeVolumeInput.dirty(event.maximumTradeVolume),
      ),
    );

    final preImage = await _getPreimageData(state);
    final preImageError = await _getPreImageError(preImage.error, state);
    final newSellAmountFromPreImage = await _getMaxSellAmountFromPreImage(
      preImage.error,
      newSellAmount,
      state.sellCoin,
    );
    if (preImageError != MarketMakerTradeFormError.none) {
      emit(
        state.copyWith(
          preImageError: preImageError,
          sellAmount:
              CoinTradeAmountInput.dirty(newSellAmountFromPreImage.toString()),
        ),
      );
    }
  }

  Future<void> _onSwapCoinsRequested(
    MarketMakerTradeFormSwapCoinsRequested event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    final newSellAmount =
        state.maximumTradeVolume.value * (state.buyCoin.value?.balance ?? 0);
    emit(
      state.copyWith(
        sellCoin: CoinSelectInput.dirty(state.buyCoin.value),
        sellAmount: CoinTradeAmountInput.dirty(newSellAmount.toString()),
        buyCoin: CoinSelectInput.dirty(state.sellCoin.value, -1, -1),
        buyAmount: const CoinTradeAmountInput.dirty('0', -1),
      ),
    );

    if (state.buyCoin.value != null) {
      final newBuyAmount = _getBuyAmountFromSellAmount(
        newSellAmount.toString(),
        state.priceFromUsdWithMargin,
      );
      emit(
        state.copyWith(
          buyAmount: CoinTradeAmountInput.dirty(newBuyAmount.toString()),
        ),
      );
    }
  }

  Future<void> _onTradeMarginChanged(
    MarketMakerTradeFormTradeMarginChanged event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    emit(
      state.copyWith(
        tradeMargin: TradeMarginInput.dirty(event.tradeMargin),
      ),
    );

    if (state.buyCoin.value != null) {
      final newBuyAmount = _getBuyAmountFromSellAmount(
        state.sellAmount.value,
        state.priceFromUsdWithMargin,
      );
      emit(
        state.copyWith(
          buyAmount: CoinTradeAmountInput.dirty(newBuyAmount.toString()),
        ),
      );
    }
  }

  Future<void> _onUpdateIntervalChanged(
    MarketMakerTradeFormUpdateIntervalChanged event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    emit(
      state.copyWith(
        updateInterval: UpdateIntervalInput.dirty(event.updateInterval),
      ),
    );
  }

  Future<void> _onClearForm(
    MarketMakerTradeFormClearRequested event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    emit(MarketMakerTradeFormState.initial());
  }

  Future<void> _onEditOrder(
    MarketMakerTradeFormEditOrderRequested event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    final sellCoin = CoinSelectInput.dirty(
      _coinsRepo.getCoin(event.tradePair.config.baseCoinId),
    );
    final buyCoin = CoinSelectInput.dirty(
      _coinsRepo.getCoin(event.tradePair.config.relCoinId),
    );
    final maxTradeVolume = event.tradePair.config.maxVolume?.value ?? 0.9;
    final minTradeVolume = event.tradePair.config.minVolume?.value ?? 0.01;
    final coinBalance = sellCoin.value?.balance ?? 0;
    final sellAmountFromVolume = maxTradeVolume * coinBalance;
    final sellAmount = CoinTradeAmountInput.dirty(
      sellAmountFromVolume.toString(),
      0,
      sellCoin.value?.balance ?? 0,
    );
    final tradeMargin = TradeMarginInput.dirty(
      event.tradePair.config.margin.toStringAsFixed(2),
    );
    final updateInterval = UpdateIntervalInput.dirty(
      event.tradePair.config.updateInterval.seconds.toString(),
    );

    emit(
      MarketMakerTradeFormState.initial().copyWith(
        sellCoin: sellCoin,
        sellAmount: sellAmount,
        minimumTradeVolume: TradeVolumeInput.dirty(minTradeVolume),
        maximumTradeVolume: TradeVolumeInput.dirty(maxTradeVolume),
        buyCoin: buyCoin,
        buyAmount: const CoinTradeAmountInput.dirty('0'),
        tradeMargin: tradeMargin,
        updateInterval: updateInterval,
      ),
    );

    final newBuyAmount = _getBuyAmountFromSellAmount(
      sellAmount.value,
      state.priceFromUsdWithMargin,
    );
    emit(
      state.copyWith(
        buyAmount: CoinTradeAmountInput.dirty(newBuyAmount.toString()),
      ),
    );
  }

  Future<void> _onOrderbookSelected(
    MarketMakerTradeFormAskOrderbookSelected event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    final askPrice = event.order.price.toDouble();
    final coinPrice = state.priceFromUsd ?? state.priceFromAmount;
    final numerator = (askPrice - coinPrice) * 100;
    final denomiator = (askPrice + coinPrice) / 2;
    final margin = numerator / denomiator;

    emit(
      state.copyWith(
        tradeMargin: TradeMarginInput.dirty(margin.toStringAsFixed(2)),
      ),
    );
  }

  Future<void> _onPreviewConfirmation(
    MarketMakerConfirmationPreviewRequested event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    emit(
      state.copyWith(
        stage: MarketMakerTradeFormStage.confirmationRequired,
        status: MarketMakerTradeFormStatus.loading,
      ),
    );

    if (state.sellCoin.value == null || state.buyCoin.value == null) {
      emit(
        state.copyWith(
          stage: MarketMakerTradeFormStage.initial,
          status: MarketMakerTradeFormStatus.error,
          preImageError: MarketMakerTradeFormError.insufficientBalanceBase,
        ),
      );
      return;
    }

    final preImage = await _getPreimageData(state);
    final preImageError = await _getPreImageError(preImage.error, state);
    if (preImageError == MarketMakerTradeFormError.none) {
      return emit(
        state.copyWith(
          tradePreImage: preImage.data,
          status: MarketMakerTradeFormStatus.success,
        ),
      );
    }

    double newSellAmount = state.sellAmount.valueAsRational.toDouble();
    final bool isInsufficientBaseBalance =
        preImageError == MarketMakerTradeFormError.insufficientBalanceBase;
    if (isInsufficientBaseBalance) {
      newSellAmount = await _getMaxSellAmountFromPreImage(
        preImage.error,
        state.sellAmount,
        state.sellCoin,
      );
    }

    emit(
      state.copyWith(
        tradePreImage: preImage.data,
        preImageError: isInsufficientBaseBalance ? null : preImageError,
        sellAmount: isInsufficientBaseBalance
            ? CoinTradeAmountInput.dirty(newSellAmount.toString())
            : state.sellAmount,
        status: isInsufficientBaseBalance
            ? MarketMakerTradeFormStatus.success
            : MarketMakerTradeFormStatus.error,
      ),
    );
    return;
  }

  Future<void> _onPreviewConfirmationCancelled(
    MarketMakerConfirmationPreviewCancelRequested event,
    Emitter<MarketMakerTradeFormState> emit,
  ) async {
    emit(
      state.copyWith(
        stage: MarketMakerTradeFormStage.initial,
        status: MarketMakerTradeFormStatus.success,
      ),
    );
  }

  double _getBuyAmountFromSellAmount(
    String sellAmount,
    double? priceFromUsdWithMargin,
  ) {
    final double sellAmountValue = double.tryParse(sellAmount) ?? 0;

    if (priceFromUsdWithMargin != null) {
      final currentPrice = priceFromUsdWithMargin;
      final double newBuyAmount = sellAmountValue * currentPrice;
      return newBuyAmount;
    }

    return 0;
  }

  /// Check for preimage errors, return the matching error state and include the
  /// new sell amount if the error is due to insufficient balance.
  Future<double> _getMaxSellAmountFromPreImage(
    BaseError? preImageError,
    CoinTradeAmountInput sellAmount,
    CoinSelectInput sellCoin,
  ) async {
    if (preImageError is TradePreimageNotSufficientBalanceError) {
      final sellAmountValue = double.tryParse(sellAmount.value) ?? 0;
      if (sellCoin.value?.abbr != preImageError.coin) {
        return sellAmountValue;
      }

      final requiredAmount = double.tryParse(preImageError.required) ?? 0;
      final sellCoinBalance = sellCoin.value?.balance ?? 0;
      final newSellAmount =
          sellAmountValue - (requiredAmount - sellCoinBalance);
      return newSellAmount;
    }

    return sellAmount.valueAsRational.toDouble();
  }

  /// Check for preimage errors, return the matching error state and include the
  /// new sell amount if the error is due to insufficient balance.
  Future<MarketMakerTradeFormError> _getPreImageError(
    BaseError? preImageError,
    MarketMakerTradeFormState formStateSnapshot,
  ) async {
    if (preImageError is TradePreimageNotSufficientBalanceError) {
      if (formStateSnapshot.sellCoin.value?.abbr != preImageError.coin) {
        return MarketMakerTradeFormError.insufficientBalanceRel;
      }

      return MarketMakerTradeFormError.insufficientBalanceBase;
    } else if (preImageError
        is TradePreimageNotSufficientBaseCoinBalanceError) {
      // if Rel coin has a parent, e.g. 1INCH-AVX-20, then the error is
      // due to insufficient balance of the parent coin
      return MarketMakerTradeFormError.insufficientBalanceRelParent;
    } else if (preImageError is TradePreimageTransportError) {
      return MarketMakerTradeFormError.insufficientTradeAmount;
    } else {
      return MarketMakerTradeFormError.none;
    }
  }

  Future<DataFromService<TradePreimage, BaseError>> _getPreimageData(
    MarketMakerTradeFormState state,
  ) async {
    try {
      final base = state.sellCoin.value?.abbr;
      final rel = state.buyCoin.value?.abbr;
      final coinPrice = state.priceFromUsd ?? state.priceFromAmount;
      final price = Rational.parse(coinPrice.toString());
      if (state.sellAmount.value.isEmpty) {
        throw ArgumentError('Sell amount must be set');
      }
      final Rational volume = Rational.parse(state.sellAmount.value);

      if (base == null || rel == null) {
        throw ArgumentError('Base and rel coins must be set');
      }

      final preimageData = await _dexRepository.getTradePreimage(
        base,
        rel,
        price,
        'setprice',
        volume,
      );

      return preimageData;
    } catch (e) {
      return DataFromService(
        error: TradePreimagePriceTooLowError(
          price: '0',
          threshold: '0',
          error: e.toString(),
        ),
      );
    }
  }

  /// Activate the coin if it is not active. If the coin is a child coin,
  /// activate the parent coin as well.
  /// Throws an error if the coin cannot be activated.
  Future<void> _autoActivateCoin(Coin? coin) async {
    if (coin == null) {
      return;
    }

    if (!coin.isActive) {
      await _coinsRepo.activateCoinsSync([coin]);
    } else {
      final Coin? parentCoin = coin.parentCoin;
      if (parentCoin != null && !parentCoin.isActive) {
        await _coinsRepo.activateCoinsSync([parentCoin]);
      }
    }
  }
}
