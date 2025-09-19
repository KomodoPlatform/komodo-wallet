import 'package:rational/rational.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/available_balance_state.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/data_from_service.dart';
import 'package:web_dex/model/dex_form_error.dart';
import 'package:web_dex/model/trade_preimage.dart';
import 'package:web_dex/model/typedef.dart';

class BridgeState {
  BridgeState({
    required this.error,
    required this.selectedTicker,
    required this.tickers,
    required this.showTickerDropdown,
    required this.showSourceDropdown,
    required this.showTargetDropdown,
    required this.sellCoin,
    required this.sellAmount,
    required this.buyAmount,
    required this.sellCoins,
    required this.bestOrder,
    required this.bestOrders,
    required this.maxSellAmount,
    required this.minSellAmount,
    required this.availableBalanceState,
    required this.preimageData,
    required this.inProgress,
    required this.step,
    required this.swapUuid,
    required this.autovalidate,
  });

  final DexFormError? error;
  final String? selectedTicker;
  final CoinsByTicker? tickers;
  final bool showTickerDropdown;
  final bool showSourceDropdown;
  final bool showTargetDropdown;
  final Coin? sellCoin;
  final Rational? sellAmount;
  final Rational? buyAmount;
  final CoinsByTicker? sellCoins;
  final BestOrder? bestOrder;
  final BestOrders? bestOrders;
  final Rational? maxSellAmount;
  final Rational? minSellAmount;
  final AvailableBalanceState availableBalanceState;
  final DataFromService<TradePreimage, BaseError>? preimageData;
  final bool inProgress;
  final BridgeStep step;
  final String? swapUuid;
  final bool autovalidate;

  static BridgeState initial() {
    return BridgeState(
      error: null,
      selectedTicker: null,
      tickers: null,
      showTickerDropdown: false,
      showSourceDropdown: false,
      showTargetDropdown: false,
      sellCoin: null,
      sellAmount: null,
      buyAmount: null,
      sellCoins: null,
      bestOrder: null,
      bestOrders: null,
      maxSellAmount: null,
      minSellAmount: null,
      availableBalanceState: AvailableBalanceState.unavailable,
      preimageData: null,
      inProgress: false,
      step: BridgeStep.form,
      swapUuid: null,
      autovalidate: false,
    );
  }

  BridgeState copyWith({
    DexFormError? Function()? error,
    String? Function()? selectedTicker,
    CoinsByTicker? Function()? tickers,
    bool Function()? showTickerDropdown,
    bool Function()? showSourceDropdown,
    bool Function()? showTargetDropdown,
    Coin? Function()? sellCoin,
    Rational? Function()? sellAmount,
    Rational? Function()? buyAmount,
    CoinsByTicker? Function()? sellCoins,
    BestOrder? Function()? bestOrder,
    BestOrders? Function()? bestOrders,
    Rational? Function()? maxSellAmount,
    Rational? Function()? minSellAmount,
    AvailableBalanceState Function()? availableBalanceState,
    DataFromService<TradePreimage, BaseError>? Function()? preimageData,
    bool Function()? inProgress,
    BridgeStep Function()? step,
    String? Function()? swapUuid,
    bool Function()? autovalidate,
  }) {
    return BridgeState(
      error: error == null ? this.error : error(),
      selectedTicker:
          selectedTicker == null ? this.selectedTicker : selectedTicker(),
      tickers: tickers == null ? this.tickers : tickers(),
      showTickerDropdown: showTickerDropdown == null
          ? this.showTickerDropdown
          : showTickerDropdown(),
      showSourceDropdown: showSourceDropdown == null
          ? this.showSourceDropdown
          : showSourceDropdown(),
      showTargetDropdown: showTargetDropdown == null
          ? this.showTargetDropdown
          : showTargetDropdown(),
      sellCoin: sellCoin == null ? this.sellCoin : sellCoin(),
      sellAmount: sellAmount == null ? this.sellAmount : sellAmount(),
      buyAmount: buyAmount == null ? this.buyAmount : buyAmount(),
      sellCoins: sellCoins == null ? this.sellCoins : sellCoins(),
      bestOrder: bestOrder == null ? this.bestOrder : bestOrder(),
      bestOrders: bestOrders == null ? this.bestOrders : bestOrders(),
      maxSellAmount:
          maxSellAmount == null ? this.maxSellAmount : maxSellAmount(),
      minSellAmount:
          minSellAmount == null ? this.minSellAmount : minSellAmount(),
      availableBalanceState: availableBalanceState == null
          ? this.availableBalanceState
          : availableBalanceState(),
      preimageData: preimageData == null ? this.preimageData : preimageData(),
      inProgress: inProgress == null ? this.inProgress : inProgress(),
      step: step == null ? this.step : step(),
      swapUuid: swapUuid == null ? this.swapUuid : swapUuid(),
      autovalidate: autovalidate == null ? this.autovalidate : autovalidate(),
    );
  }
}

enum BridgeStep {
  form,
  confirm;
}
