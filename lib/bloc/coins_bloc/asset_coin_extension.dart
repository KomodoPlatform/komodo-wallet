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

    final CoinType? type = _getCoinTypeFromProtocol(protocol);
    if (type == null) {
      throw ArgumentError.value(
          protocol.subClass, 'protocol type', 'Unsupported protocol type');
    }

    // temporary measure to get metadata, like `wallet_only`, that isn't exposed
    // by the SDK (and might be phased out completely later on)
    final config = protocol.config;

    return Coin(
      type: type,
      abbr: id.id,
      name: id.name,
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

  CoinType? _getCoinTypeFromProtocol(ProtocolClass protocol) {
    switch (protocol.subClass) {
      case CoinSubClass.ftm20:
        return CoinType.ftm20;
      case CoinSubClass.arbitrum:
        return CoinType.arb20;
      // ignore: deprecated_member_use
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
}
