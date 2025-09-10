import 'package:rational/rational.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/data_from_service.dart';
import 'package:web_dex/model/dex_form_error.dart';
import 'package:web_dex/model/trade_preimage.dart';

abstract class BridgeEvent {
  const BridgeEvent();
}

class BridgeInit extends BridgeEvent {
  const BridgeInit({required this.ticker});

  final String ticker;
}

class BridgeTickerChanged extends BridgeEvent {
  const BridgeTickerChanged(this.ticker);

  final String? ticker;
}

class BridgeUpdateTickers extends BridgeEvent {
  const BridgeUpdateTickers();
}

class BridgeShowTickerDropdown extends BridgeEvent {
  const BridgeShowTickerDropdown(this.show);

  final bool show;
}

class BridgeShowSourceDropdown extends BridgeEvent {
  const BridgeShowSourceDropdown(this.show);

  final bool show;
}

class BridgeShowTargetDropdown extends BridgeEvent {
  const BridgeShowTargetDropdown(this.show);

  final bool show;
}

class BridgeUpdateSellCoins extends BridgeEvent {
  const BridgeUpdateSellCoins();
}

class BridgeSetSellCoin extends BridgeEvent {
  const BridgeSetSellCoin(this.coin);

  final Coin coin;
}

class BridgeUpdateBestOrders extends BridgeEvent {
  const BridgeUpdateBestOrders({this.silent = false});

  final bool silent;
}

class BridgeSelectBestOrder extends BridgeEvent {
  const BridgeSelectBestOrder(this.order);

  final BestOrder? order;
}

class BridgeSetError extends BridgeEvent {
  const BridgeSetError(this.error);

  final DexFormError error;
}

class BridgeClearErrors extends BridgeEvent {
  const BridgeClearErrors();
}

class BridgeUpdateMaxSellAmount extends BridgeEvent {
  const BridgeUpdateMaxSellAmount([this.setLoadingStatus = false]);

  final bool setLoadingStatus;
}

class BridgeReInit extends BridgeEvent {
  const BridgeReInit();
}

class BridgeLogout extends BridgeEvent {
  const BridgeLogout();
}

// 'max', 'half' buttons
class BridgeAmountButtonClick extends BridgeEvent {
  BridgeAmountButtonClick(this.fraction);

  final double fraction;
}

class BridgeSellAmountChange extends BridgeEvent {
  BridgeSellAmountChange(this.value);

  final String value;
}

class BridgeSetSellAmount extends BridgeEvent {
  BridgeSetSellAmount(this.amount);

  final Rational? amount;
}

class BridgeGetMinSellAmount extends BridgeEvent {
  const BridgeGetMinSellAmount();
}

class BridgeUpdateFees extends BridgeEvent {
  const BridgeUpdateFees();
}

class BridgeSetPreimage extends BridgeEvent {
  const BridgeSetPreimage(this.preimageData);

  final DataFromService<TradePreimage, BaseError>? preimageData;
}

class BridgeSetInProgress extends BridgeEvent {
  const BridgeSetInProgress(this.inProgress);

  final bool inProgress;
}

class BridgeSubmitClick extends BridgeEvent {
  const BridgeSubmitClick();
}

class BridgeSetWalletIsReady extends BridgeEvent {
  const BridgeSetWalletIsReady(this.isReady);

  final bool isReady;
}

class BridgeBackClick extends BridgeEvent {
  const BridgeBackClick();
}

class BridgeStartSwap extends BridgeEvent {
  const BridgeStartSwap();
}

class BridgeClear extends BridgeEvent {
  const BridgeClear();
}

class BridgeVerifyOrderVolume extends BridgeEvent {
  const BridgeVerifyOrderVolume();
}
