import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/wallet.dart';

extension KdfAuthMetadataExtension on KomodoDefiSdk {
  Future<bool> walletExists(String walletId) async {
    final users = await auth.getUsers();
    return users.any((user) => user.walletId.name == walletId);
  }

  Future<Wallet?> currentWallet() async {
    final user = await auth.currentUser;
    return user?.wallet;
  }

  Future<void> addActivatedCoins(Iterable<String> coins) async {
    final existingCoins = (await auth.currentUser)
            ?.metadata
            .valueOrNull<List<String>>('activated_coins') ??
        [];

    final mergedCoins = <dynamic>{...existingCoins, ...coins}.toList();
    await auth.setOrRemoveActiveUserKeyValue('activated_coins', mergedCoins);
  }

  Future<void> removeActivatedCoins(List<String> coins) async {
    final existingCoins = (await auth.currentUser)
            ?.metadata
            .valueOrNull<List<String>>('activated_coins') ??
        [];

    existingCoins.removeWhere((coin) => coins.contains(coin));
    await auth.setOrRemoveActiveUserKeyValue('activated_coins', existingCoins);
  }

  Future<void> confirmSeedBackup({bool hasBackup = true}) async {
    await auth.setOrRemoveActiveUserKeyValue('has_backup', true);
  }

  Future<void> setWalletType(WalletType type) async {
    await auth.setOrRemoveActiveUserKeyValue('type', type.name);
  }

  Future<List<Coin>> getCustomTokens() async {
    return (await auth.currentUser)
            ?.metadata
            .valueOrNull<List<JsonMap>>('custom_coins')
            ?.map((JsonMap coin) => Coin.fromJson(coin))
            .toList() ??
        [];
  }

  Future<void> addCustomToken(Coin coin) async {
    final existingCoins = (await auth.currentUser)
            ?.metadata
            .valueOrNull<List<Coin>>('custom_tokens')
            ?.map((Coin coin) => coin.toJson()) ??
        [];

    final mergedCoins = <JsonMap>{...existingCoins, coin.toJson()}.toList();
    await auth.setOrRemoveActiveUserKeyValue('custom_tokens', mergedCoins);
  }
}

extension CoinKdfAssetConversionExtension on Coin {
  Asset toAsset({
    bool isCustomToken = false,
    int chainId = 0,
  }) {
    return Asset(
      id: AssetId(
          id: abbr,
          name: name,
          symbol: AssetSymbol(
            assetConfigId: '0',
            coinGeckoId: coingeckoId,
            coinPaprikaId: coinpaprikaId,
          ),
          chainId: AssetChainId(chainId: chainId),
          derivationPath: derivationPath ?? '',
          subClass: type.toCoinSubClass()),
      protocol: Erc20Protocol.fromJson({
        'type': parentCoin?.type.toCoinSubClass().formatted ??
            type.toCoinSubClass().formatted,
        'chain_id': chainId,
        'nodes': [],
        'swap_contract_address': swapContractAddress,
        'fallback_swap_contract': fallbackSwapContract,
        'protocol': {
          'protocol_data': {
            'platform': parentCoin?.abbr,
            'contract_address': protocolData?.contractAddress,
          },
        }
      }).copyWith(isCustomToken: true),
    );
  }
}
