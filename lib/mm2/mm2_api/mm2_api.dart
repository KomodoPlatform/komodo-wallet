import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api_nft.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api_trezor.dart';
import 'package:web_dex/mm2/mm2_api/rpc/active_swaps/active_swaps_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/cancel_order/cancel_order_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/convert_address/convert_address_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/disable_coin/disable_coin_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/electrum/electrum_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/enable/enable_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/enable_tendermint/enable_tendermint_token.dart';
import 'package:web_dex/mm2/mm2_api/rpc/enable_tendermint/enable_tendermint_with_assets.dart';
import 'package:web_dex/mm2/mm2_api/rpc/get_enabled_coins/get_enabled_coins_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/import_swaps/import_swaps_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/import_swaps/import_swaps_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/kmd_rewards_info/kmd_rewards_info_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_maker_vol/max_maker_vol_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_maker_vol/max_maker_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/market_maker_bot_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_taker_vol/max_taker_vol_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_taker_vol/max_taker_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/min_trading_vol/min_trading_vol.dart';
import 'package:web_dex/mm2/mm2_api/rpc/min_trading_vol/min_trading_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_balance/my_balance_req.dart';
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
    trezor = Mm2ApiTrezor(_call);
    nft = Mm2ApiNft(_call);
  }

  final MM2 _mm2;
  late Mm2ApiTrezor trezor;
  late Mm2ApiNft nft;
  VersionResponse? _versionResponse;

  Future<List<Coin>?> getEnabledCoins(List<Coin> knownCoins) async {
    dynamic response;
    try {
      response = await _call(GetEnabledCoinsReq());
    } catch (e) {
      log(
        'Error getting enabled coins: ${e.toString()}',
        path: 'api => getEnabledCoins => _call',
        isError: true,
      );
      return null;
    }

    dynamic resultJson;
    try {
      resultJson = jsonDecode(response)['result'];
    } catch (e, s) {
      log(
        'Error parsing of enabled coins response: ${e.toString()}',
        path: 'api => getEnabledCoins => jsonDecode',
        trace: s,
        isError: true,
      );
      return null;
    }

    final List<Coin> list = [];
    if (resultJson is List) {
      for (dynamic item in resultJson) {
        final Coin? coin = knownCoins.firstWhereOrNull(
          (Coin known) => known.abbr == item['ticker'],
        );

        if (coin != null) {
          coin.address = item['address'];
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
    dynamic response;
    try {
      response = await _call(coinRequests);
      log(
        response,
        path: 'api => _enableEthWithTokensCoins',
      );
    } catch (e, s) {
      log(
        'Error enabling coins: ${e.toString()}',
        path: 'api => _enableEthWithTokensCoins => _call',
        trace: s,
        isError: true,
      );
      return;
    }

    dynamic json;
    try {
      json = jsonDecode(response);
    } catch (e, s) {
      log(
        'Error parsing of enable coins response: ${e.toString()}',
        path: 'api => _enableEthWithTokensCoins => jsonDecode',
        trace: s,
        isError: true,
      );
      return;
    }

    if (json is List) {
      for (var item in json) {
        if (item['error'] != null) {
          log(
            item['error'],
            path: 'api => _enableEthWithTokensCoins:',
            isError: true,
          );
        }
      }

      return;
    } else if (json is Map<String, dynamic> && json['error'] != null) {
      log(
        json['error'],
        path: 'api => _enableEthWithTokensCoins:',
        isError: true,
      );
      return;
    }
  }

  Future<void> _enableErc20Coins(List<EnableErc20Request> coinRequests) async {
    dynamic response;
    try {
      response = await _call(coinRequests);
      log(
        response,
        path: 'api => _enableErc20Coins',
      );
    } catch (e, s) {
      log(
        'Error enabling coins: ${e.toString()}',
        path: 'api => _enableErc20Coins => _call',
        trace: s,
        isError: true,
      );
      return;
    }

    List<dynamic> json;
    try {
      json = jsonDecode(response);
    } catch (e, s) {
      log(
        'Error parsing of enable coins response: ${e.toString()}',
        path: 'api => _enableEthWithTokensCoins => jsonDecode',
        trace: s,
        isError: true,
      );
      return;
    }
    for (dynamic item in json) {
      if (item['error'] != null) {
        log(
          item['error'],
          path: 'api => _enableEthWithTokensCoins:',
          isError: true,
        );
      }
    }
  }

  Future<void> _enableElectrumCoins(List<ElectrumReq> electrumRequests) async {
    try {
      final dynamic response = await _call(electrumRequests);
      log(
        response,
        path: 'api => _enableElectrumCoins => _call',
      );
    } catch (e, s) {
      log(
        'Error enabling electrum coins: ${e.toString()}',
        path: 'api => _enableElectrumCoins => _call',
        trace: s,
        isError: true,
      );
      return;
    }
  }

  Future<void> _enableTendermintWithAssets(
    List<EnableTendermintWithAssetsRequest> request,
  ) async {
    try {
      final dynamic response = await _call(request);
      log(
        response,
        path: 'api => _enableTendermintWithAssets => _call',
      );
    } catch (e, s) {
      log(
        'Error enabling tendermint coins: ${e.toString()}',
        path: 'api => _enableTendermintWithAssets => _call',
        trace: s,
        isError: true,
      );
      return;
    }
  }

  Future<void> _enableTendermintTokens(
    List<EnableTendermintTokenRequest> request,
    EnableTendermintWithAssetsRequest? tendermintWithAssetsRequest,
  ) async {
    try {
      if (tendermintWithAssetsRequest != null) {
        await _call(tendermintWithAssetsRequest);
      }
      final dynamic response = await _call(request);
      log(
        response,
        path: 'api => _enableTendermintToken => _call',
      );
    } catch (e, s) {
      log(
        'Error enabling tendermint tokens: ${e.toString()}',
        path: 'api => _enableTendermintToken => _call',
        trace: s,
        isError: true,
      );
      return;
    }
  }

  Future<void> _enableSlpTokens(
    List<EnableSlp> requests,
  ) async {
    try {
      final dynamic response = await _call(requests);
      log(
        response,
        path: 'api => _enableSlpTokens => _call',
      );
    } catch (e, s) {
      log(
        'Error enabling bch coins: ${e.toString()}',
        path: 'api => _enableSlpTokens => _call',
        trace: s,
        isError: true,
      );
      return;
    }
  }

  Future<void> _enableBchWithTokens(
    List<EnableBchWithTokens> requests,
  ) async {
    try {
      final dynamic response = await _call(requests);
      log(
        response,
        path: 'api => _enableBchWithTokens => _call',
      );
    } catch (e, s) {
      log(
        'Error enabling bch coins: ${e.toString()}',
        path: 'api => _enableBchWithTokens => _call',
        trace: s,
        isError: true,
      );
      return;
    }
  }

  Future<void> disableCoin(String coin) async {
    try {
      await _call(DisableCoinReq(coin: coin));
    } catch (e, s) {
      log(
        'Error disabling $coin: ${e.toString()}',
        path: 'api=> disableCoin => _call',
        trace: s,
        isError: true,
      );
      return;
    }
  }

  Future<String?> getBalance(String abbr) async {
    dynamic response;
    try {
      response = await _call(MyBalanceReq(coin: abbr));
    } catch (e, s) {
      log(
        'Error getting balance $abbr: ${e.toString()}',
        path: 'api => getBalance => _call',
        trace: s,
        isError: true,
      );
      return null;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response);
    } catch (e, s) {
      log(
        'Error parsing of get balance $abbr response: ${e.toString()}',
        path: 'api => getBalance => jsonDecode',
        trace: s,
        isError: true,
      );
      return null;
    }

    return json['balance'];
  }

  Future<MaxMakerVolResponse?> getMaxMakerVol(String abbr) async {
    dynamic response;
    try {
      response = await _call(MaxMakerVolRequest(coin: abbr));
    } catch (e, s) {
      log(
        'Error getting max maker vol $abbr: ${e.toString()}',
        path: 'api => getMaxMakerVol => _call',
        trace: s,
        isError: true,
      );
      return _fallbackToBalance(abbr);
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response);
    } catch (e, s) {
      log(
        'Error parsing of max maker vol $abbr response: ${e.toString()}',
        path: 'api => getMaxMakerVol => jsonDecode',
        trace: s,
        isError: true,
      );
      return _fallbackToBalance(abbr);
    }

    final error = json['error'];
    if (error != null) {
      log(
        'Error parsing of max maker vol $abbr response: ${error.toString()}',
        path: 'api => getMaxMakerVol => error',
        isError: true,
      );
      return _fallbackToBalance(abbr);
    }

    try {
      return MaxMakerVolResponse.fromJson(json['result']);
    } catch (e, s) {
      log(
        'Error constructing MaxMakerVolResponse for $abbr: ${e.toString()}',
        path: 'api => getMaxMakerVol => fromJson',
        trace: s,
        isError: true,
      );
      return _fallbackToBalance(abbr);
    }
  }

  Future<MaxMakerVolResponse?> _fallbackToBalance(String abbr) async {
    final balance = await getBalance(abbr);
    if (balance == null) {
      log(
        'Failed to retrieve balance for fallback construction of MaxMakerVolResponse for $abbr',
        path: 'api => _fallbackToBalance',
        isError: true,
      );
      return null;
    }

    final balanceValue = MaxMakerVolResponseValue(decimal: balance);
    return MaxMakerVolResponse(
      volume: balanceValue,
      balance: balanceValue,
    );
  }

  Future<MaxTakerVolResponse?> _fallbackToBalanceTaker(String abbr) async {
    final balance = await getBalance(abbr);
    if (balance == null) {
      log(
        'Failed to retrieve balance for fallback construction of MaxTakerVolResponse for $abbr',
        path: 'api => _fallbackToBalanceTaker',
        isError: true,
      );
      return null;
    }
    final rational = Rational.parse(balance);
    final result = MaxTakerVolumeResponseResult(
      numer: rational.numerator.toString(),
      denom: rational.denominator.toString(),
    );

    return MaxTakerVolResponse(
      coin: abbr,
      result: result,
    );
  }

  Future<Map<String, dynamic>?> getActiveSwaps(
    ActiveSwapsRequest request,
  ) async {
    try {
      final String response = await _call(request);
      return jsonDecode(response);
    } catch (e, s) {
      log(
        'Error getting active swaps: ${e.toString()}',
        path: 'api => getActiveSwaps',
        trace: s,
        isError: true,
      );
      return <String, dynamic>{'error': 'something went wrong'};
    }
  }

  Future<Map<String, dynamic>?> validateAddress(
    String coinAbbr,
    String address,
  ) async {
    try {
      final dynamic response = await _call(
        ValidateAddressRequest(coin: coinAbbr, address: address),
      );
      final Map<String, dynamic> json = jsonDecode(response);

      return json;
    } catch (e, s) {
      log(
        'Error validating address $coinAbbr: ${e.toString()}',
        path: 'api => validateAddress',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> withdraw(WithdrawRequest request) async {
    try {
      final dynamic response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);

      return json;
    } catch (e, s) {
      log(
        'Error withdrawing ${request.params.coin}: ${e.toString()}',
        path: 'api => withdraw',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendRawTransaction(
    SendRawTransactionRequest request,
  ) async {
    try {
      final dynamic response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);

      return json;
    } catch (e, s) {
      log(
        'Error sending raw transaction ${request.coin}: ${e.toString()}',
        path: 'api => sendRawTransaction',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionsHistory(
    MyTxHistoryRequest request,
  ) async {
    try {
      final dynamic response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);

      return json;
    } catch (e, s) {
      log(
        'Error sending raw transaction ${request.coin}: ${e.toString()}',
        path: 'api => getTransactions',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionsHistoryV2(
    MyTxHistoryV2Request request,
  ) async {
    try {
      final dynamic response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);

      return json;
    } catch (e, s) {
      log(
        'Error sending raw transaction ${request.params.coin}: ${e.toString()}',
        path: 'api => getTransactions',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRewardsInfo(
    KmdRewardsInfoRequest request,
  ) async {
    try {
      final dynamic response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);

      return json;
    } catch (e, s) {
      log(
        'Error getting rewards info: ${e.toString()}',
        path: 'api => getRewardsInfo',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBestOrders(BestOrdersRequest request) async {
    try {
      final String response = await _call(request);
      return jsonDecode(response);
    } catch (e, s) {
      log(
        'Error getting best orders ${request.coin}: ${e.toString()}',
        path: 'api => getBestOrders',
        trace: s,
        isError: true,
      );
      return <String, dynamic>{'error': e};
    }
  }

  Future<Map<String, dynamic>> sell(SellRequest request) async {
    try {
      final String response = await _call(request);
      return jsonDecode(response);
    } catch (e, s) {
      log(
        'Error sell ${request.base}/${request.rel}: ${e.toString()}',
        path: 'api => sell',
        trace: s,
        isError: true,
      );
      return <String, dynamic>{'error': e};
    }
  }

  Future<Map<String, dynamic>?> setprice(SetPriceRequest request) async {
    try {
      final String response = await _call(request);
      return jsonDecode(response);
    } catch (e, s) {
      log(
        'Error setprice ${request.base}/${request.rel}: ${e.toString()}',
        path: 'api => setprice',
        trace: s,
        isError: true,
      );
      return <String, dynamic>{'error': e};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(CancelOrderRequest request) async {
    try {
      final String response = await _call(request);
      return jsonDecode(response);
    } catch (e, s) {
      log(
        'Error cancelOrder ${request.uuid}: ${e.toString()}',
        path: 'api => cancelOrder',
        trace: s,
        isError: true,
      );
      return <String, dynamic>{'error': e};
    }
  }

  Future<Map<String, dynamic>> getSwapStatus(MySwapStatusReq request) async {
    try {
      final String response = await _call(request);
      return jsonDecode(response);
    } catch (e, s) {
      log(
        'Error sell getting swap status ${request.uuid}: ${e.toString()}',
        path: 'api => getSwapStatus',
        trace: s,
        isError: true,
      );
      return <String, dynamic>{'error': 'something went wrong'};
    }
  }

  Future<MyOrdersResponse?> getMyOrders() async {
    try {
      final MyOrdersRequest request = MyOrdersRequest();
      final String response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);
      if (json['error'] != null) {
        return null;
      }
      return MyOrdersResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting my orders: ${e.toString()}',
        path: 'api => getMyOrders',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<String> getRawSwapData(MyRecentSwapsRequest request) async {
    return await _call(request);
  }

  Future<MyRecentSwapsResponse?> getMyRecentSwaps(
    MyRecentSwapsRequest request,
  ) async {
    try {
      final String response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);
      if (json['error'] != null) {
        return null;
      }
      return MyRecentSwapsResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting my recent swaps: ${e.toString()}',
        path: 'api => getMyRecentSwaps',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<OrderStatusResponse?> getOrderStatus(String uuid) async {
    try {
      final OrderStatusRequest request = OrderStatusRequest(uuid: uuid);
      final String response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);
      if (json['error'] != null) {
        return null;
      }
      return OrderStatusResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting order status $uuid: ${e.toString()}',
        path: 'api => getOrderStatus',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<ImportSwapsResponse?> importSwaps(ImportSwapsRequest request) async {
    try {
      final String response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);
      if (json['error'] != null) {
        return null;
      }
      return ImportSwapsResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error import swaps : ${e.toString()}',
        path: 'api => importSwaps',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<RecoverFundsOfSwapResponse?> recoverFundsOfSwap(
    RecoverFundsOfSwapRequest request,
  ) async {
    try {
      final String response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);
      if (json['error'] != null) {
        log(
          'Error recovering funds of swap ${request.uuid}: ${json['error']}',
          path: 'api => recoverFundsOfSwap',
          isError: true,
        );
        return null;
      }
      return RecoverFundsOfSwapResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error recovering funds of swap ${request.uuid}: ${e.toString()}',
        path: 'api => recoverFundsOfSwap',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<MaxTakerVolResponse?> getMaxTakerVolume(
    MaxTakerVolRequest request,
  ) async {
    try {
      final String response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);
      if (json['error'] != null) {
        return await _fallbackToBalanceTaker(request.coin);
      }
      return MaxTakerVolResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting max taker volume ${request.coin}: ${e.toString()}',
        path: 'api => getMaxTakerVolume',
        trace: s,
        isError: true,
      );
      return await _fallbackToBalanceTaker(request.coin);
    }
  }

  Future<MinTradingVolResponse?> getMinTradingVol(
    MinTradingVolRequest request,
  ) async {
    try {
      final String response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);
      if (json['error'] != null) {
        return null;
      }
      return MinTradingVolResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting min trading volume ${request.coin}: ${e.toString()}',
        path: 'api => getMinTradingVol',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<OrderbookResponse> getOrderbook(OrderbookRequest request) async {
    try {
      final String response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);

      if (json['error'] != null) {
        return OrderbookResponse(
          request: request,
          error: json['error'],
        );
      }

      return OrderbookResponse(
        request: request,
        result: Orderbook.fromJson(json),
      );
    } catch (e, s) {
      log(
        'Error getting orderbook ${request.base}/${request.rel}: ${e.toString()}',
        path: 'api => getOrderbook',
        trace: s,
        isError: true,
      );

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
      final String response = await _call(request);
      final Map<String, dynamic> json = jsonDecode(response);
      if (json['error'] != null) {
        return null;
      }
      return OrderBookDepthResponse.fromJson(json);
    } catch (e, s) {
      log(
        'Error getting orderbook depth $request: ${e.toString()}',
        path: 'api => getOrderBookDepth',
        trace: s,
      );
    }
    return null;
  }

  Future<
      ApiResponse<TradePreimageRequest, TradePreimageResponseResult,
          Map<String, dynamic>>> getTradePreimage(
    TradePreimageRequest request,
  ) async {
    try {
      final String response = await _call(request);
      final Map<String, dynamic> responseJson = await jsonDecode(response);
      if (responseJson['error'] != null) {
        return ApiResponse(request: request, error: responseJson);
      }
      return ApiResponse(
        request: request,
        result: TradePreimageResponse.fromJson(responseJson).result,
      );
    } catch (e, s) {
      log(
        'Error getting trade preimage ${request.base}/${request.rel}: ${e.toString()}',
        path: 'api => getTradePreimage',
        trace: s,
        isError: true,
      );
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
      final dynamic response = await _call(marketMakerBotRequest.toJson());
      log(
        response,
        path: 'api => ${marketMakerBotRequest.method} => _call',
      );

      if (response is String) {
        final Map<String, dynamic> responseJson = jsonDecode(response);
        if (responseJson['error'] != null) {
          throw RpcException(RpcError.fromJson(responseJson));
        }
      }
    } catch (e, s) {
      log(
        'Error starting or stopping simple market maker bot: ${e.toString()}',
        path: 'api => start_simple_market_maker_bot => _call',
        trace: s,
        isError: true,
      );
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
      final String response = await _call(request);
      final Map<String, dynamic> responseJson = jsonDecode(response);
      return responseJson['result']?['address'];
    } catch (e, s) {
      log(
        'Convert address error: ${e.toString()}',
        path: 'api => convertLegacyAddress',
        trace: s,
        isError: true,
      );
      return null;
    }
  }

  Future<void> stop() async {
    await _call(StopReq());
  }

  Future<dynamic> _call(dynamic req) async {
    final MM2Status mm2Status = await _mm2.status();
    if (mm2Status != MM2Status.rpcIsUp) {
      return '{"error": "Error, mm2 status: $mm2Status"}';
    }

    final dynamic response = await _mm2.call(req);

    return response;
  }
}
