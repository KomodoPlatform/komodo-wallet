import 'package:decimal/decimal.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/model/cex_price.dart' show CexPrice;
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';

Coin setCoin({
  double? usdPrice,
  double? change24h,
  String? coinAbbr,
  double? balance,
}) {
  final id = AssetId(
    id: coinAbbr ?? 'KMD',
    name: 'Komodo',
    parentId: null,
    symbol: AssetSymbol(
      assetConfigId: coinAbbr ?? 'KMD',
      coinGeckoId: 'komodo',
      coinPaprikaId: 'kmd-komodo',
    ),
    derivationPath: "m/44'/141'/0'",
    chainId: AssetChainId(chainId: 0),
    subClass: CoinSubClass.smartChain,
  );

  return Coin(
    abbr: coinAbbr ?? 'KMD',
    id: id,
    activeByDefault: true,
    logoImageUrl: null,
    coingeckoId: "komodo",
    coinpaprikaId: "kmd-komodo",
    derivationPath: "m/44'/141'/0'",
    explorerUrl: "https://kmdexplorer.io/address/",
    explorerAddressUrl: "address/",
    explorerTxUrl: "tx/",
    fallbackSwapContract: null,
    isTestCoin: false,
    mode: CoinMode.standard,
    name: 'Komodo',
    priority: 30,
    protocolData: null,
    protocolType: 'UTXO',
    parentCoin: null,
    state: CoinState.inactive,
    swapContractAddress: null,
    type: CoinType.smartChain,
    walletOnly: false,
    usdPrice: CexPrice(
      assetId: id,
      lastUpdated: DateTime.now(),
      price: Decimal.tryParse(usdPrice.toString()),
      change24h: Decimal.tryParse(change24h.toString()),
    ),
  );
}
