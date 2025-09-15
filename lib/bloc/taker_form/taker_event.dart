import 'package:rational/rational.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/dex_form_error.dart';
import 'package:web_dex/model/trade_preimage.dart';

abstract class TakerEvent {
  const TakerEvent();
}

class TakerCoinSelectorOpen extends TakerEvent {
  TakerCoinSelectorOpen(this.isOpen);

  final bool isOpen;
}

class TakerOrderSelectorOpen extends TakerEvent {
  TakerOrderSelectorOpen(this.isOpen);

  final bool isOpen;
}

class TakerCoinSelectorClick extends TakerEvent {}

class TakerOrderSelectorClick extends TakerEvent {}

class TakerSetSellCoin extends TakerEvent {
  TakerSetSellCoin(
    this.coin, {
    this.autoSelectOrderAbbr,
    this.setOnlyIfNotSet = false,
  });

  final Coin? coin;
  final String? autoSelectOrderAbbr;
  final bool setOnlyIfNotSet;
}

class TakerSelectOrder extends TakerEvent {
  TakerSelectOrder(this.order);

  final BestOrder? order;
}

class TakerSetDefaults extends TakerEvent {}

class TakerAddError extends TakerEvent {
  TakerAddError(this.error);

  final DexFormError error;
}

class TakerClearErrors extends TakerEvent {}

class TakerUpdateBestOrders extends TakerEvent {
  TakerUpdateBestOrders({this.autoSelectOrderAbbr});

  final String? autoSelectOrderAbbr;
}

class TakerClear extends TakerEvent {}

class TakerSellAmountChange extends TakerEvent {
  TakerSellAmountChange(this.value);

  final String value;
}

class TakerSetSellAmount extends TakerEvent {
  TakerSetSellAmount(this.amount);

  final Rational? amount;
}

class TakerUpdateMaxSellAmount extends TakerEvent {
  const TakerUpdateMaxSellAmount([this.setLoadingStatus = false]);
  final bool setLoadingStatus;
}

class TakerGetMinSellAmount extends TakerEvent {}

// 'max', 'half' buttons
class TakerAmountButtonClick extends TakerEvent {
  TakerAmountButtonClick(this.fraction);

  final double fraction;
}

class TakerUpdateFees extends TakerEvent {}

class TakerSetPreimage extends TakerEvent {
  TakerSetPreimage(this.tradePreimage);

  final TradePreimage? tradePreimage;
}

class TakerFormSubmitClick extends TakerEvent {}

class TakerBackButtonClick extends TakerEvent {}

class TakerStartSwap extends TakerEvent {}

class TakerReInit extends TakerEvent {}

class TakerSetInProgress extends TakerEvent {
  TakerSetInProgress(this.value);

  final bool value;
}

class TakerSetWalletIsReady extends TakerEvent {
  TakerSetWalletIsReady(this.ready);

  final bool ready;
}

class TakerVerifyOrderVolume extends TakerEvent {}
