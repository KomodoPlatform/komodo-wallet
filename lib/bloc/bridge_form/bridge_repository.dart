import 'dart:async';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/setprice/setprice_request.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/model/typedef.dart';

class BridgeRepository {
  BridgeRepository(this._mm2Api, this._kdfSdk, this._coinsRepository);

  final Mm2Api _mm2Api;
  final KomodoDefiSdk _kdfSdk;
  final CoinsRepo _coinsRepository;

  Future<CoinsByTicker?> getSellCoins(CoinsByTicker? tickers) async {
    if (tickers == null) return null;

    final CoinsByTicker sellCoins = tickers.map(
      (key, value) => MapEntry(key, List<Coin>.from(value)),
    );

    return sellCoins;
  }

  Future<CoinsByTicker> getAvailableTickers() async {
    List<Coin> coins = _coinsRepository.getKnownCoins();
    coins = removeWalletOnly(coins);
    coins = removeSuspended(coins, await _kdfSdk.auth.isSignedIn());

    final CoinsByTicker coinsByTicker = convertToCoinsByTicker(coins);
    final CoinsByTicker multiProtocolCoins =
        removeSingleProtocol(coinsByTicker);

    return multiProtocolCoins;
  }

  Future<Map<String, dynamic>?> setprice(SetPriceRequest request) async {
    return _mm2Api.setprice(request);
  }
}
