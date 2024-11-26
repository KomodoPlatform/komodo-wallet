import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api_nft.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api_trezor.dart';
import 'package:web_dex/mm2/mm2_api/rpc/active_swaps/active_swaps_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/cancel_order/cancel_order_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/convert_address/convert_address_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/directly_connected_peers/get_directly_connected_peers.dart';
import 'package:web_dex/mm2/mm2_api/rpc/directly_connected_peers/get_directly_connected_peers_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/disable_coin/disable_coin_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/electrum/electrum_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/enable/enable_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/enable_tendermint/enable_tendermint_token.dart';
import 'package:web_dex/mm2/mm2_api/rpc/enable_tendermint/enable_tendermint_with_assets.dart';
import 'package:web_dex/mm2/mm2_api/rpc/get_enabled_coins/get_enabled_coins_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/import_swaps/import_swaps_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/import_swaps/import_swaps_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/kmd_rewards_info/kmd_rewards_info_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/market_maker_bot_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_maker_vol/max_maker_vol_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_maker_vol/max_maker_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_taker_vol/max_taker_vol_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_taker_vol/max_taker_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/min_trading_vol/min_trading_vol.dart';
import 'package:web_dex/mm2/mm2_api/rpc/min_trading_vol/min_trading_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_orders/my_orders_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_orders/my_orders_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_recent_swaps/my_recent_swaps_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_recent_swaps/my_recent_swaps_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_swap_status/my_swap_status_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_tx_history/my_tx_history_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_tx_history/my_tx_history_v2_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/order_status/order_status_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/order_status/order_status_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook/orderbook_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook/orderbook_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook_depth/orderbook_depth_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook_depth/orderbook_depth_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/recover_funds_of_swap/recover_funds_of_swap_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/recover_funds_of_swap/recover_funds_of_swap_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/rpc_error.dart';
import 'package:web_dex/mm2/mm2_api/rpc/sell/sell_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/send_raw_transaction/send_raw_transaction_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/setprice/setprice_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/show_priv_key/show_priv_key_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/show_priv_key/show_priv_key_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/stop/stop_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trade_preimage/trade_preimage_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trade_preimage/trade_preimage_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/validateaddress/validateaddress_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/version/version_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/withdraw_request.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/orderbook/orderbook.dart';
import 'package:web_dex/shared/utils/utils.dart';

final Mm2Api mm2Api = Mm2Api(mm2: mm2);

class Mm2Api {
  Mm2Api({
    required MM2 mm2,
  }) : _mm2 = mm2 {
    trezor = Mm2ApiTrezor(_mm2.call);
    nft = Mm2ApiNft(_mm2.call);
  }

  final MM2 _mm2;
  late Mm2ApiTrezor trezor;
  late Mm2ApiNft nft;
  VersionResponse? _versionResponse;

  Future<List<Coin>?> getEnabledCoins(List<Coin> knownCoins) async {
    JsonMap response;
    try {
      response = await _mm2.call(GetEnabledCoinsReq());
    } catch (e) {
      log(
        'Error getting enabled coins: $e',
        path: 'api => getEnabledCoins => _call',
        isError: true,
      ).ignore();
      return null;
    }

    dynamic resultJson;
    try {
      resultJson = response['result'];
    } catch (e, s) {
      log(
        'Error parsing of enabled coins response: $e',
        path: 'api => getEnabledCoins => jsonDecode',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }

    final List<Coin> list = [];
    if (resultJson is List) {
      for (final dynamic item in resultJson) {
        final Coin? coin = knownCoins.firstWhereOrNull(
          (Coin known) => known.abbr == item['ticker'],
        );

        if (coin != null) {
          coin.address = item['address'] as String?;
          list.add(coin);
        }
      }
    }

    return list;
  }

  Future<void> enableCoins({
    required List<EnableEthWithTokensRequest>? ethWithTokensRequests,
    required List<ElectrumReq>? electrumCoinRequests,
    required List<EnableErc20Request>? erc20Requests,
    required List<EnableTendermintWithAssetsRequest>? tendermintRequests,
    required List<EnableTendermintTokenRequest>? tendermintTokenRequests,
    required List<EnableBchWithTokens>? bchWithTokens,
    required List<EnableSlp>? slpTokens,
  }) async {
    if (ethWithTokensRequests != null && ethWithTokensRequests.isNotEmpty) {
      await _enableEthWithTokensCoins(ethWithTokensRequests);
    }
    if (erc20Requests != null && erc20Requests.isNotEmpty) {
      await _enableErc20Coins(erc20Requests);
    }
    if (electrumCoinRequests != null && electrumCoinRequests.isNotEmpty) {
      await _enableElectrumCoins(electrumCoinRequests);
    }
    if (tendermintRequests != null && tendermintRequests.isNotEmpty) {
      await _enableTendermintWithAssets(tendermintRequests);
    }
    if (tendermintTokenRequests != null && tendermintTokenRequests.isNotEmpty) {
      await _enableTendermintTokens(tendermintTokenRequests, null);
    }
    if (bchWithTokens != null && bchWithTokens.isNotEmpty) {
      await _enableBchWithTokens(bchWithTokens);
    }
    if (slpTokens != null && slpTokens.isNotEmpty) {
      await _enableSlpTokens(slpTokens);
    }
  }

  Future<void> _enableEthWithTokensCoins(
    List<EnableEthWithTokensRequest> coinRequests,
  ) async {
    return _callMany(
      coinRequests,
      (dynamic request) async {
        final JsonMap json = await _mm2.call(request);
        if (json['error'] != null) {
          log(
            json['error'].toString(),
            path: 'api => _enableEthWithTokensCoins:',
            isError: true,
          ).ignore();
          return;
        }
      },
      logPath: 'api => _enableEthWithTokensCoins => _call',
    );
  }

  Future<void> _enableErc20Coins(List<EnableErc20Request> coinRequests) async {
    return _callMany(
      coinRequests,
      (dynamic request) async {
        final JsonMap json = await _mm2.call(request);

        if (json['error'] != null) {
          log(
            json['error'].toString(),
            path: 'api => _enableEthWithTokensCoins:',
            isError: true,
          ).ignore();
        }
      },
      logPath: 'api => _enableErc20Coins => _call',
    );
  }

  Future<void> _enableElectrumCoins(List<ElectrumReq> electrumRequests) async {
    await _callMany(
      electrumRequests,
      _mm2.call,
      logPath: 'api => _enableElectrumCoins => _call',
    );
  }

  Future<void> _enableTendermintWithAssets(
    List<EnableTendermintWithAssetsRequest> tendermintRequests,
  ) async {
    return _callMany(
      tendermintRequests,
      _mm2.call,
      logPath: 'api => _enableTendermintWithAssets => _call',
    );
  }

  Future<void> _enableTendermintTokens(
    List<EnableTendermintTokenRequest> request,
    EnableTendermintWithAssetsRequest? tendermintWithAssetsRequest,
  ) async {
    try {
      if (tendermintWithAssetsRequest != null) {
        await _mm2.call(tendermintWithAssetsRequest);
      }
      return _callMany(
        request,
        _mm2.call,
        logPath: 'api => _enableTendermintToken => _call',
      );
    } catch (e, s) {
      log(
        'Error enabling tendermint tokens: $e',
        path: 'api => _enableTendermintToken => _call',
        trace: s,
        isError: true,
      ).ignore();
      return;
    }
  }

  Future<void> _enableSlpTokens(
    List<EnableSlp> requests,
  ) async {
    return _callMany(
      requests,
      _mm2.call,
      logPath: 'api => _enableSlpTokens => _call',
    );
  }

  Future<void> _enableBchWithTokens(
    List<EnableBchWithTokens> requests,
  ) async {
    return _callMany(
      requests,
      _mm2.call,
      logPath: 'api => _enableBchWithTokens => _call',
    );
  }

  Future<void> disableCoin(String coin) async {
    try {
      await _mm2.call(DisableCoinReq(coin: coin));
    } catch (e, s) {
      log(
        'Error disabling $coin: $e',
        path: 'api=> disableCoin => _call',
        trace: s,
        isError: true,
      ).ignore();
      return;
    }
  }

  Future<MaxMakerVolResponse?> getMaxMakerVol(String abbr) async {
    JsonMap? response;
    try {
      response = await _mm2.call(MaxMakerVolRequest(coin: abbr));
    } catch (e, s) {
      log(
        'Error getting max maker vol $abbr: $e',
        path: 'api => getMaxMakerVol => _call',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }

    final error = response['error'];
    if (error != null) {
      log(
        'Error parsing of max maker vol $abbr response: $error',
        path: 'api => getMaxMakerVol => error',
        isError: true,
      ).ignore();
      return null;
    }

    return MaxMakerVolResponse.fromJson(
      Map<String, dynamic>.from(response['result'] as Map? ?? {}),
    );
  }

  Future<Map<String, dynamic>?> getActiveSwaps(
    ActiveSwapsRequest request,
  ) async {
    try {
      return await _mm2.call(request) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error getting active swaps: $e',
        path: 'api => getActiveSwaps',
        trace: s,
        isError: true,
      ).ignore();
      return <String, dynamic>{'error': 'something went wrong'};
    }
  }

  Future<Map<String, dynamic>?> validateAddress(
    String coinAbbr,
    String address,
  ) async {
    try {
      return await _mm2.call(
        ValidateAddressRequest(coin: coinAbbr, address: address),
      );
    } catch (e, s) {
      log(
        'Error validating address $coinAbbr: $e',
        path: 'api => validateAddress',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<Map<String, dynamic>?> withdraw(WithdrawRequest request) async {
    try {
      return await _mm2.call(request) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error withdrawing ${request.params.coin}: $e',
        path: 'api => withdraw',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendRawTransaction(
    SendRawTransactionRequest request,
  ) async {
    try {
      return await _mm2.call(request) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error sending raw transaction ${request.coin}: $e',
        path: 'api => sendRawTransaction',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionsHistory(
    MyTxHistoryRequest request,
  ) async {
    try {
      return await _mm2.call(request) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error sending raw transaction ${request.coin}: $e',
        path: 'api => getTransactions',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionsHistoryV2(
    MyTxHistoryV2Request request,
  ) async {
    try {
      return await _mm2.call(request) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error sending raw transaction ${request.params.coin}: $e',
        path: 'api => getTransactions',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRewardsInfo(
    KmdRewardsInfoRequest request,
  ) async {
    try {
      return await _mm2.call(request) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error getting rewards info: $e',
        path: 'api => getRewardsInfo',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBestOrders(BestOrdersRequest request) async {
    try {
      return await _mm2.call(request) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error getting best orders ${request.coin}: $e',
        path: 'api => getBestOrders',
        trace: s,
        isError: true,
      ).ignore();
      return <String, dynamic>{'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sell(SellRequest request) async {
    try {
      return await _mm2.call(request);
    } catch (e, s) {
      log(
        'Error sell ${request.base}/${request.rel}: $e',
        path: 'api => sell',
        trace: s,
        isError: true,
      ).ignore();
      return <String, dynamic>{'error': e};
    }
  }

  Future<Map<String, dynamic>?> setprice(SetPriceRequest request) async {
    try {
      return await _mm2.call(request) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error setprice ${request.base}/${request.rel}: $e',
        path: 'api => setprice',
        trace: s,
        isError: true,
      ).ignore();
      return <String, dynamic>{'error': e};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(CancelOrderRequest request) async {
    try {
      return await _mm2.call(request);
    } catch (e, s) {
      log(
        'Error cancelOrder ${request.uuid}: $e',
        path: 'api => cancelOrder',
        trace: s,
        isError: true,
      ).ignore();
      return <String, dynamic>{'error': e};
    }
  }

  Future<Map<String, dynamic>> getSwapStatus(MySwapStatusReq request) async {
    try {
      return await _mm2.call(request);
    } catch (e, s) {
      log(
        'Error sell getting swap status ${request.uuid}: $e',
        path: 'api => getSwapStatus',
        trace: s,
        isError: true,
      ).ignore();
      return <String, dynamic>{'error': 'something went wrong'};
    }
  }

  Future<MyOrdersResponse?> getMyOrders() async {
    try {
      final MyOrdersRequest request = MyOrdersRequest();
      final response = await _mm2.call(request);
      if (response['error'] != null) {
        return null;
      }
      return MyOrdersResponse.fromJson(response);
    } catch (e, s) {
      log(
        'Error getting my orders: $e',
        path: 'api => getMyOrders',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<String> getRawSwapData(MyRecentSwapsRequest request) async {
    return jsonEncode(await _mm2.call(request));
  }

  Future<MyRecentSwapsResponse?> getMyRecentSwaps(
    MyRecentSwapsRequest request,
  ) async {
    try {
      final response = await _mm2.call(request);
      if (response['error'] != null) {
        return null;
      }
      return MyRecentSwapsResponse.fromJson(response);
    } catch (e, s) {
      log(
        'Error getting my recent swaps: $e',
        path: 'api => getMyRecentSwaps',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<OrderStatusResponse?> getOrderStatus(String uuid) async {
    try {
      final OrderStatusRequest request = OrderStatusRequest(uuid: uuid);
      final response = await _mm2.call(request);
      if (response['error'] != null) {
        return null;
      }
      return OrderStatusResponse.fromJson(response);
    } catch (e, s) {
      log(
        'Error getting order status $uuid: $e',
        path: 'api => getOrderStatus',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<ImportSwapsResponse?> importSwaps(ImportSwapsRequest request) async {
    try {
      final JsonMap response = await _mm2.call(request);
      if (response['error'] != null) {
        return null;
      }
      return ImportSwapsResponse.fromJson(response);
    } catch (e, s) {
      log(
        'Error import swaps : $e',
        path: 'api => importSwaps',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<RecoverFundsOfSwapResponse?> recoverFundsOfSwap(
    RecoverFundsOfSwapRequest request,
  ) async {
    try {
      final JsonMap json = await _mm2.call(request);
      if (json['error'] != null) {
        log(
          'Error recovering funds of swap ${request.uuid}: ${json['error']}',
          path: 'api => recoverFundsOfSwap',
          isError: true,
        ).ignore();
        return null;
      }
      return RecoverFundsOfSwapResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error recovering funds of swap ${request.uuid}: $e',
        path: 'api => recoverFundsOfSwap',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<MaxTakerVolResponse?> getMaxTakerVolume(
    MaxTakerVolRequest request,
  ) async {
    try {
      final JsonMap json = await _mm2.call(request);
      if (json['error'] != null) {
        return null;
      }
      return MaxTakerVolResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting max taker volume ${request.coin}: $e',
        path: 'api => getMaxTakerVolume',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<MinTradingVolResponse?> getMinTradingVol(
    MinTradingVolRequest request,
  ) async {
    try {
      final JsonMap json = await _mm2.call(request);
      if (json['error'] != null) {
        return null;
      }
      return MinTradingVolResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting min trading volume ${request.coin}: $e',
        path: 'api => getMinTradingVol',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<OrderbookResponse> getOrderbook(OrderbookRequest request) async {
    try {
      final JsonMap json = await _mm2.call(request);

      if (json['error'] != null) {
        return OrderbookResponse(
          request: request,
          error: json['error'] as String?,
        );
      }

      return OrderbookResponse(
        request: request,
        result: Orderbook.fromJson(json),
      );
    } catch (e, s) {
      log(
        'Error getting orderbook ${request.base}/${request.rel}: $e',
        path: 'api => getOrderbook',
        trace: s,
        isError: true,
      ).ignore();

      return OrderbookResponse(
        request: request,
        error: e.toString(),
      );
    }
  }

  Future<OrderBookDepthResponse?> getOrderBookDepth(
    List<List<String>> pairs,
  ) async {
    final request = OrderBookDepthReq(pairs: pairs);
    try {
      final JsonMap json = await _mm2.call(request);
      if (json['error'] != null) {
        return null;
      }
      return OrderBookDepthResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting orderbook depth $request: $e',
        path: 'api => getOrderBookDepth',
        trace: s,
      ).ignore();
    }
    return null;
  }

  Future<
      ApiResponse<TradePreimageRequest, TradePreimageResponseResult,
          Map<String, dynamic>>> getTradePreimage(
    TradePreimageRequest request,
  ) async {
    try {
      final JsonMap responseJson = await _mm2.call(request);
      if (responseJson['error'] != null) {
        return ApiResponse(request: request, error: responseJson);
      }
      return ApiResponse(
        request: request,
        result: TradePreimageResponse.fromJson(responseJson).result,
      );
    } catch (e, s) {
      log(
        'Error getting trade preimage ${request.base}/${request.rel}: $e',
        path: 'api => getTradePreimage',
        trace: s,
        isError: true,
      ).ignore();
      return ApiResponse(
        request: request,
      );
    }
  }

  /// Start or stop the market maker bot.
  /// The [MarketMakerBotRequest.method] field determines whether the start
  /// or stop method is called.
  ///
  /// The [MarketMakerBotRequest] is sent to the MM2 RPC API.
  ///
  /// The response, or exceptions, are logged.
  ///
  /// Throws [Exception] if an error occurs.
  Future<void> startStopMarketMakerBot(
    MarketMakerBotRequest marketMakerBotRequest,
  ) async {
    try {
      final JsonMap response = await _mm2.call(marketMakerBotRequest.toJson());
      log(
        response.toString(),
        path: 'api => ${marketMakerBotRequest.method} => _call',
      ).ignore();

      if (response['error'] != null) {
        throw RpcException(RpcError.fromJson(response));
      }
    } catch (e, s) {
      log(
        'Error starting or stopping simple market maker bot: $e',
        path: 'api => start_simple_market_maker_bot => _call',
        trace: s,
        isError: true,
      ).ignore();
      rethrow;
    }
  }

  Future<String?> version() async {
    _versionResponse ??= await _getMm2Version();

    return _versionResponse?.result;
  }

  Future<VersionResponse?> _getMm2Version() async {
    try {
      final String versionResult = await mm2.version();
      return VersionResponse(result: versionResult);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> convertLegacyAddress(ConvertAddressRequest request) async {
    try {
      final JsonMap responseJson = await _mm2.call(request);
      return responseJson['result']?['address'] as String?;
    } catch (e, s) {
      log(
        'Convert address error: $e',
        path: 'api => convertLegacyAddress',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<void> stop() async {
    await _mm2.call(StopReq());
  }

  Future<void> _callMany<T>(
    List<T> requests,
    Future<dynamic> Function(T request) processor, {
    required String logPath,
    bool concurrent = false,
    bool enableLogging = true,
  }) async {
    try {
      if (concurrent) {
        await Future.wait(
          requests.map((request) async {
            final dynamic response = await processor(request);
            if (enableLogging) {
              log(
                response.toString(),
                path: logPath,
              ).ignore();
            }
          }),
        );
      } else {
        for (final request in requests) {
          final dynamic response = await processor(request);
          if (enableLogging) {
            log(
              response.toString(),
              path: logPath,
            ).ignore();
          }
        }
      }
    } catch (e, s) {
      if (enableLogging) {
        log(
          'Error processing requests: $e',
          path: logPath,
          trace: s,
          isError: true,
        ).ignore();
      }
      return;
    }
  }

  Future<ShowPrivKeyResponse?> showPrivKey(
    ShowPrivKeyRequest request,
  ) async {
    try {
      final JsonMap json = await _mm2.call(request);
      if (json['error'] != null) {
        return null;
      }
      return ShowPrivKeyResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting privkey ${request.coin}: ${e.toString()}',
        path: 'api => showPrivKey',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }
  }

  Future<GetDirectlyConnectedPeersResponse> getDirectlyConnectedPeers(
    GetDirectlyConnectedPeers request,
  ) async {
    try {
      final JsonMap json = await _mm2.call(request);
      if (json['error'] != null) {
        log(
          'Error getting directly connected peers: ${json['error']}',
          isError: true,
          path: 'api => getDirectlyConnectedPeers',
        ).ignore();
        throw Exception('Failed to get directly connected peers');
      }

      return GetDirectlyConnectedPeersResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting directly connected peers',
        path: 'api => getDirectlyConnectedPeers',
        trace: s,
        isError: true,
      ).ignore();
      rethrow;
    }
  }
}
