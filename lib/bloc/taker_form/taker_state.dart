import 'package:rational/rational.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:komodo_wallet/model/available_balance_state.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/model/dex_form_error.dart';
import 'package:komodo_wallet/model/trade_preimage.dart';

class TakerState {
  TakerState({
    required this.step,
    required this.inProgress,
    this.sellCoin,
    this.selectedOrder,
    this.bestOrders,
    required this.showCoinSelector,
    required this.showOrderSelector,
    this.sellAmount,
    this.buyAmount,
    required this.errors,
    this.tradePreimage,
    this.maxSellAmount,
    this.minSellAmount,
    required this.autovalidate,
    this.swapUuid,
    required this.availableBalanceState,
  });

  factory TakerState.initial() {
    return TakerState(
      step: TakerStep.form,
      inProgress: false,
      sellCoin: null,
      selectedOrder: null,
      bestOrders: null,
      showCoinSelector: false,
      showOrderSelector: false,
      errors: [],
      tradePreimage: null,
      maxSellAmount: null,
      minSellAmount: null,
      autovalidate: false,
      swapUuid: null,
      availableBalanceState: AvailableBalanceState.initial,
    );
  }

  TakerStep step;
  bool inProgress;
  Coin? sellCoin;
  BestOrder? selectedOrder;
  BestOrders? bestOrders;
  bool showCoinSelector;
  bool showOrderSelector;
  Rational? sellAmount;
  Rational? buyAmount;
  List<DexFormError> errors;
  TradePreimage? tradePreimage;
  Rational? maxSellAmount;
  Rational? minSellAmount;
  bool autovalidate;
  String? swapUuid;
  AvailableBalanceState availableBalanceState;

  // Function arguments needed to handle nullable props
  // https://bloclibrary.dev/#/fluttertodostutorial
  // https://stackoverflow.com/questions/68009392/dart-custom-copywith-method-with-nullable-properties
  TakerState copyWith({
    TakerStep Function()? step,
    bool Function()? inProgress,
    Coin? Function()? sellCoin,
    BestOrder? Function()? selectedOrder,
    BestOrders? Function()? bestOrders,
    bool Function()? showCoinSelector,
    bool Function()? showOrderSelector,
    Rational? Function()? sellAmount,
    Rational? Function()? buyAmount,
    List<DexFormError> Function()? errors,
    TradePreimage? Function()? tradePreimage,
    Rational? Function()? maxSellAmount,
    Rational? Function()? minSellAmount,
    bool Function()? autovalidate,
    String? Function()? swapUuid,
    AvailableBalanceState Function()? availableBalanceState,
  }) {
    return TakerState(
      step: step == null ? this.step : step(),
      inProgress: inProgress == null ? this.inProgress : inProgress(),
      sellCoin: sellCoin == null ? this.sellCoin : sellCoin(),
      selectedOrder:
          selectedOrder == null ? this.selectedOrder : selectedOrder(),
      bestOrders: bestOrders == null ? this.bestOrders : bestOrders(),
      showCoinSelector:
          showCoinSelector == null ? this.showCoinSelector : showCoinSelector(),
      showOrderSelector: showOrderSelector == null
          ? this.showOrderSelector
          : showOrderSelector(),
      sellAmount: sellAmount == null ? this.sellAmount : sellAmount(),
      buyAmount: buyAmount == null ? this.buyAmount : buyAmount(),
      errors: errors == null ? this.errors : errors(),
      tradePreimage:
          tradePreimage == null ? this.tradePreimage : tradePreimage(),
      maxSellAmount:
          maxSellAmount == null ? this.maxSellAmount : maxSellAmount(),
      minSellAmount:
          minSellAmount == null ? this.minSellAmount : minSellAmount(),
      autovalidate: autovalidate == null ? this.autovalidate : autovalidate(),
      swapUuid: swapUuid == null ? this.swapUuid : swapUuid(),
      availableBalanceState: availableBalanceState == null
          ? this.availableBalanceState
          : availableBalanceState(),
    );
  }
}

enum TakerStep {
  form,
  confirm,
}
