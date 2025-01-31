import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';

extension AssetCoinExtension on Asset {
  Coin toCoin() {
    // Create protocol data if needed
    ProtocolData? protocolData;
    protocolData = ProtocolData(
      platform: id.parentId?.id ?? '',
      contractAddress: '',
    );

    final CoinType type = protocol.subClass.toCoinType();
    // temporary measure to get metadata, like `wallet_only`, that isn't exposed
    // by the SDK (and might be phased out completely later on)
    // TODO: Remove this once the SDK exposes all the necessary metadata
    final config = protocol.config;

    return Coin(
      type: type,
      abbr: id.id,
      id: id,
      name: id.name,
      logoImageUrl: '',
      explorerUrl: config.valueOrNull<String>('explorer_url') ?? '',
      explorerTxUrl: config.valueOrNull<String>('explorer_tx_url') ?? '',
      explorerAddressUrl:
          config.valueOrNull<String>('explorer_address_url') ?? '',
      protocolType: protocol.subClass.ticker,
      protocolData: protocolData,
      isTestCoin: protocol.isTestnet,
      coingeckoId: id.symbol.coinGeckoId,
      swapContractAddress: config.valueOrNull<String>('swap_contract_address'),
      fallbackSwapContract:
          config.valueOrNull<String>('fallback_swap_contract'),
      priority: 0, // Default priority
      state: CoinState.inactive,
      walletOnly: config.valueOrNull<bool>('wallet_only') ?? false,
      mode: CoinMode.standard,
      derivationPath: id.derivationPath,
    );
  }
}

extension CoinTypeExtension on CoinSubClass {
  CoinType toCoinType() {
    switch (this) {
      case CoinSubClass.ftm20:
        return CoinType.ftm20;
      case CoinSubClass.arbitrum:
        return CoinType.arb20;
      case CoinSubClass.slp:
        return CoinType.slp;
      case CoinSubClass.qrc20:
        return CoinType.qrc20;
      case CoinSubClass.avx20:
        return CoinType.avx20;
      case CoinSubClass.smartChain:
        return CoinType.smartChain;
      case CoinSubClass.moonriver:
        return CoinType.mvr20;
      case CoinSubClass.ethereumClassic:
        return CoinType.etc;
      case CoinSubClass.hecoChain:
        return CoinType.hco20;
      case CoinSubClass.hrc20:
        return CoinType.hrc20;
      case CoinSubClass.tendermintToken:
        return CoinType.iris;
      case CoinSubClass.tendermint:
        return CoinType.cosmos;
      case CoinSubClass.ubiq:
        return CoinType.ubiq;
      case CoinSubClass.bep20:
        return CoinType.bep20;
      case CoinSubClass.matic:
        return CoinType.plg20;
      case CoinSubClass.utxo:
        return CoinType.utxo;
      case CoinSubClass.smartBch:
        return CoinType.sbch;
      case CoinSubClass.erc20:
        return CoinType.erc20;
      case CoinSubClass.krc20:
        return CoinType.krc20;
      default:
        return CoinType.utxo;
    }
  }

  bool isEvmProtocol() {
    switch (this) {
      case CoinSubClass.avx20:
      case CoinSubClass.bep20:
      case CoinSubClass.ftm20:
      case CoinSubClass.matic:
      case CoinSubClass.hrc20:
      case CoinSubClass.arbitrum:
      case CoinSubClass.moonriver:
      case CoinSubClass.moonbeam:
      case CoinSubClass.ethereumClassic:
      case CoinSubClass.ubiq:
      case CoinSubClass.krc20:
      case CoinSubClass.ewt:
      case CoinSubClass.hecoChain:
      case CoinSubClass.rskSmartBitcoin:
      case CoinSubClass.erc20:
        return true;
      default:
        return false;
    }
  }
}

extension CoinSubClassExtension on CoinType {
  CoinSubClass toCoinSubClass() {
    switch (this) {
      case CoinType.ftm20:
        return CoinSubClass.ftm20;
      case CoinType.arb20:
        return CoinSubClass.arbitrum;
      case CoinType.slp:
        return CoinSubClass.slp;
      case CoinType.qrc20:
        return CoinSubClass.qrc20;
      case CoinType.avx20:
        return CoinSubClass.avx20;
      case CoinType.smartChain:
        return CoinSubClass.smartChain;
      case CoinType.mvr20:
        return CoinSubClass.moonriver;
      case CoinType.etc:
        return CoinSubClass.ethereumClassic;
      case CoinType.hco20:
        return CoinSubClass.hecoChain;
      case CoinType.hrc20:
        return CoinSubClass.hrc20;
      case CoinType.iris:
        return CoinSubClass.tendermintToken;
      case CoinType.cosmos:
        return CoinSubClass.tendermint;
      case CoinType.ubiq:
        return CoinSubClass.ubiq;
      case CoinType.bep20:
        return CoinSubClass.bep20;
      case CoinType.plg20:
        return CoinSubClass.matic;
      case CoinType.utxo:
        return CoinSubClass.utxo;
      case CoinType.sbch:
        return CoinSubClass.smartBch;
      case CoinType.erc20:
        return CoinSubClass.erc20;
      case CoinType.krc20:
        return CoinSubClass.krc20;
    }
  }
}
