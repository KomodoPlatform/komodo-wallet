import 'package:rational/rational.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_maker_vol/max_maker_vol_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_maker_vol/max_maker_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_taker_vol/max_taker_vol_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_taker_vol/max_taker_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/min_trading_vol/min_trading_vol.dart';
import 'package:web_dex/mm2/mm2_api/rpc/min_trading_vol/min_trading_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_recent_swaps/my_recent_swaps_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_swap_status/my_swap_status_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/sell/sell_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/sell/sell_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trade_preimage/trade_preimage_errors.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trade_preimage/trade_preimage_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trade_preimage/trade_preimage_response.dart';
import 'package:web_dex/model/data_from_service.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/trade_preimage.dart';
import 'package:web_dex/services/mappers/trade_preimage_mappers.dart';
import 'package:web_dex/shared/utils/utils.dart';

class DexRepository {
  DexRepository(this._mm2Api);

  final Mm2Api _mm2Api;

  Future<SellResponse> sell(SellRequest request) async {
    try {
      final Map<String, dynamic> response = await _mm2Api.sell(request);
      return SellResponse.fromJson(response);
    } catch (e) {
      return SellResponse(error: TextError.fromString(e.toString()));
    }
  }

  Future<DataFromService<TradePreimage, BaseError>> getTradePreimage(
    String base,
    String rel,
    Rational price,
    String swapMethod, [
    Rational? volume,
    bool max = false,
  ]) async {
    final request = TradePreimageRequest(
      base: base,
      rel: rel,
      price: price,
      volume: volume,
      swapMethod: swapMethod,
      max: max,
    );
    final ApiResponse<TradePreimageRequest, TradePreimageResponseResult,
            Map<String, dynamic>> response =
        await _mm2Api.getTradePreimage(request);

    final Map<String, dynamic>? error = response.error;
    final TradePreimageResponseResult? result = response.result;
    if (error != null) {
      return DataFromService(
        error: tradePreimageErrorFactory.getError(error, response.request),
      );
    }
    if (result == null) {
      return DataFromService(error: TextError(error: 'Something wrong'));
    }
    try {
      return DataFromService(
        data: mapTradePreimageResponseResultToTradePreimage(
          result,
          response.request,
        ),
      );
    } catch (e, s) {
      log(
        e.toString(),
        path:
            'swaps_service => getTradePreimage => mapTradePreimageResponseToTradePreimage',
        trace: s,
        isError: true,
      );
      return DataFromService(error: TextError(error: 'Something wrong'));
    }
  }

  Future<Rational?> getMaxTakerVolume(String coinAbbr) async {
    final MaxTakerVolResponse? response =
        await _mm2Api.getMaxTakerVolume(MaxTakerVolRequest(coin: coinAbbr));
    if (response == null) {
      return null;
    }

    return fract2rat(response.result.toJson());
  }

  Future<Rational?> getMaxMakerVolume(String coinAbbr) async {
    final MaxMakerVolResponse? response =
        await _mm2Api.getMaxMakerVolume(MaxMakerVolRequest(coin: coinAbbr));
    if (response == null) {
      return null;
    }

    return fract2rat(response.volume.toFractionalJson());
  }

  Future<Rational?> getMinTradingVolume(String coinAbbr) async {
    final MinTradingVolResponse? response =
        await _mm2Api.getMinTradingVol(MinTradingVolRequest(coin: coinAbbr));
    if (response == null) {
      return null;
    }

    return fract2rat(response.result.toJson());
  }

  Future<List<Swap>?> getRecentSwaps(MyRecentSwapsRequest request) async {
    return null;
  }

  Future<BestOrders> getBestOrders(BestOrdersRequest request) async {
    Map<String, dynamic>? response;
    try {
      response = await _mm2Api.getBestOrders(request);
    } catch (e) {
      return BestOrders(error: TextError.fromString(e.toString()));
    }

    final isErrorResponse =
        (response?['error'] as String?)?.isNotEmpty ?? false;
    final hasResult =
        (response?['result'] as Map<String, dynamic>?)?.isNotEmpty ?? false;

    if (isErrorResponse) {
      return BestOrders(error: TextError(error: response!['error']!));
    }

    if (!hasResult) {
      return BestOrders(error: TextError(error: 'Orders not found!'));
    }

    try {
      return BestOrders.fromJson(response!);
    } catch (e, s) {
      log('Error parsing best_orders response: $e', trace: s, isError: true);

      return BestOrders(
        error: TextError(
          error: 'Something went wrong! Unexpected response format.',
        ),
      );
    }
  }

  Future<Swap> getSwapStatus(String swapUuid) async {
    final response =
        await _mm2Api.getSwapStatus(MySwapStatusReq(uuid: swapUuid));

    if (response['error'] != null) {
      throw TextError(error: response['error']);
    }

    return Swap.fromJson(response['result']);
  }

  Future<void> waitOrderbookAvailability({
    int retries = 10,
    int interval = 300,
  }) async {
    BestOrders orders;

    for (int attempt = 0; attempt < retries; attempt++) {
      orders = await getBestOrders(
        BestOrdersRequest(
          coin: defaultDexCoin,
          type: BestOrdersRequestType.number,
          number: 1,
          action: 'sell',
        ),
      );

      if (orders.result?.isNotEmpty ?? false) {
        return;
      }

      await Future.delayed(Duration(milliseconds: interval));
    }
  }
}
