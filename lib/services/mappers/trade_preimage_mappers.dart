import 'package:web_dex/mm2/mm2_api/rpc/trade_preimage/trade_preimage_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trade_preimage/trade_preimage_response.dart';
import 'package:web_dex/model/trade_preimage.dart';

TradePreimage mapTradePreimageResponseResultToTradePreimage(
    TradePreimageResponseResult result, TradePreimageRequest request) {
  return TradePreimage(
    baseCoinFee: result.baseCoinFee,
    relCoinFee: result.relCoinFee,
    takerFee: result.takerFee,
    feeToSendTakerFee: result.feeToSendTakerFee,
    totalFees: result.totalFees,
    volume: result.volume,
    volumeFract: result.volumeFraction,
    request: request,
  );
}
