import 'package:collection/collection.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/model/cex_price.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/model/electrum.dart';
import 'package:web_dex/model/hd_account/hd_account.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/utils/utils.dart';

class Coin {
  Coin({
    required this.type,
    required this.abbr,
    required this.name,
    required this.explorerUrl,
    required this.explorerTxUrl,
    required this.explorerAddressUrl,
    required this.protocolType,
    required this.protocolData,
    required this.isTestCoin,
    required this.coingeckoId,
    required this.fallbackSwapContract,
    required this.electrum,
    required this.nodes,
    required this.rpcUrls,
    required this.bchdUrls,
    required this.priority,
    required this.state,
    this.decimals = 8,
    this.parentCoin,
    this.trezorCoin,
    this.derivationPath,
    this.accounts,
    this.usdPrice,
    this.coinpaprikaId,
    this.activeByDefault = false,
    required String? swapContractAddress,
    required bool walletOnly,
    required this.mode,
  })  : _swapContractAddress = swapContractAddress,
        _walletOnly = walletOnly;

  factory Coin.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> globalCoinJson,
  ) {
    final List<Electrum> electrumList = _getElectrumFromJson(json);
    final List<CoinNode> nodesList = _getNodesFromJson(json);
    final List<String> bchdUrls = _getBchdUrlsFromJson(json);
    final List<CoinNode> rpcUrls = _getRpcUrlsFromJson(json);
    final String explorerUrl = _getExplorerFromJson(json);
    final String explorerTxUrl = _getExplorerTxUrlFromJson(json);
    final String explorerAddressUrl = _getExplorerAddressUrlFromJson(json);

    final String? jsonType = json['type'];
    final String coinAbbr = json['abbr'];
    final CoinType? type = getCoinType(jsonType, coinAbbr);
    if (type == null) {
      throw ArgumentError.value(jsonType, 'json[\'type\']');
    }
    // The code below is commented out because of the latest changes
    // to coins config to include "offline" coins so that the user can
    // see the coins fail to activate instead of disappearing from the
    // We should still figure out if there is a new criteria instead of
    // blindly parsing the JSON as-is.
    // if (type != CoinType.slp) {
    //   assert(
    //     electrumList.isNotEmpty ||
    //         nodesList.isNotEmpty ||
    //         rpcUrls.isNotEmpty ||
    //         bchdUrls.isNotEmpty,
    //     'The ${json['abbr']} doesn\'t have electrum, nodes and rpc_urls',
    //   );
    // }

    return Coin(
      type: type,
      abbr: coinAbbr,
      coingeckoId: json['coingecko_id'],
      coinpaprikaId: json['coinpaprika_id'],
      name: json['name'],
      electrum: electrumList,
      nodes: nodesList,
      rpcUrls: rpcUrls,
      bchdUrls: bchdUrls,
      swapContractAddress: json['swap_contract_address'],
      fallbackSwapContract: json['fallback_swap_contract'],
      activeByDefault: json['active'] ?? false,
      explorerUrl: explorerUrl,
      explorerTxUrl: explorerTxUrl,
      explorerAddressUrl: explorerAddressUrl,
      protocolType: _getProtocolType(globalCoinJson),
      protocolData: _parseProtocolData(globalCoinJson),
      isTestCoin: json['is_testnet'] ?? false,
      walletOnly: json['wallet_only'] ?? false,
      trezorCoin: globalCoinJson['trezor_coin'],
      derivationPath: globalCoinJson['derivation_path'],
      decimals: json['decimals'] ?? 8,
      priority: json['priority'],
      mode: _getCoinMode(json),
      state: CoinState.inactive,
    );
  }

  final String abbr;
  final String name;
  final String? coingeckoId;
  final String? coinpaprikaId;
  final List<Electrum> electrum;
  final List<CoinNode> nodes;
  final List<String> bchdUrls;
  final List<CoinNode> rpcUrls;
  final CoinType type;
  final bool activeByDefault;
  final String protocolType;
  final ProtocolData? protocolData;
  final String explorerUrl;
  final String explorerTxUrl;
  final String explorerAddressUrl;
  final String? trezorCoin;
  final String? derivationPath;
  final int decimals;
  CexPrice? usdPrice;
  final bool isTestCoin;
  String? address;
  List<HdAccount>? accounts;
  double _balance = 0;
  String? _swapContractAddress;
  String? fallbackSwapContract;
  WalletType? enabledType;
  bool _walletOnly;
  final int priority;
  Coin? parentCoin;
  final CoinMode mode;
  CoinState state;

  bool get walletOnly => _walletOnly || appWalletOnlyAssetList.contains(abbr);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'coin': abbr,
      'name': name,
      'coingecko_id': coingeckoId,
      'coinpaprika_id': coinpaprikaId,
      'electrum': electrum.map((Electrum e) => e.toJson()).toList(),
      'nodes': nodes.map((CoinNode n) => n.toJson()).toList(),
      'rpc_urls': rpcUrls.map((CoinNode n) => n.toJson()).toList(),
      'bchd_urls': bchdUrls,
      'type': getCoinTypeName(type),
      'active': activeByDefault,
      'protocol': <String, dynamic>{
        'type': protocolType,
        'protocol_data': protocolData?.toJson(),
      },
      'is_testnet': isTestCoin,
      'wallet_only': walletOnly,
      'trezor_coin': trezorCoin,
      'derivation_path': derivationPath,
      'decimals': decimals,
      'priority': priority,
      'mode': mode.toString(),
      'state': state.toString(),
      'swap_contract_address': _swapContractAddress,
      'fallback_swap_contract': fallbackSwapContract,
    };
  }

  String? get swapContractAddress =>
      _swapContractAddress ?? parentCoin?.swapContractAddress;
  bool get isSuspended => state == CoinState.suspended;
  bool get isActive => state == CoinState.active;
  bool get isActivating => state == CoinState.activating;
  bool get isInactive => state == CoinState.inactive;

  double sendableBalance = 0;

  double get balance {
    switch (enabledType) {
      case WalletType.trezor:
        return _totalHdBalance ?? 0.0;
      default:
        return _balance;
    }
  }

  set balance(double value) {
    switch (enabledType) {
      case WalletType.trezor:
        log('Warning: Trying to set $abbr balance,'
            ' while it was activated in ${enabledType!.name} mode. Ignoring.');
        break;
      default:
        _balance = value;
    }
  }

  double? get _totalHdBalance {
    if (accounts == null) return null;

    double? totalBalance;
    for (HdAccount account in accounts!) {
      double accountBalance = 0.0;
      for (HdAddress address in account.addresses) {
        accountBalance += address.balance.spendable;
      }
      totalBalance = (totalBalance ?? 0.0) + accountBalance;
    }

    return totalBalance;
  }

  double? get usdBalance {
    if (usdPrice == null) return null;
    if (balance == 0) return 0;

    return balance.toDouble() * (usdPrice?.price.toDouble() ?? 0.00);
  }

  String get getFormattedUsdBalance =>
      usdBalance == null ? '\$0.00' : '\$${formatAmt(usdBalance!)}';

  String get typeName => getCoinTypeName(type);
  String get typeNameWithTestnet => typeName + (isTestCoin ? ' (TESTNET)' : '');

  bool get isIrisToken => protocolType == 'TENDERMINTTOKEN';

  bool get need0xPrefixForTxHash => isErcType;

  bool get isErcType => protocolType == 'ERC20' || protocolType == 'ETH';

  bool get isTxMemoSupported =>
      type == CoinType.iris || type == CoinType.cosmos;

  String? get defaultAddress {
    switch (enabledType) {
      case WalletType.trezor:
        return _defaultTrezorAddress;
      default:
        return address;
    }
  }

  bool get isCustomFeeSupported {
    return type != CoinType.iris && type != CoinType.cosmos;
  }

  bool get hasFaucet => coinsWithFaucet.contains(abbr);

  bool get hasTrezorSupport {
    if (trezorCoin == null) return false;
    if (excludedAssetListTrezor.contains(abbr)) return false;
    if (checkSegwitByAbbr(abbr)) return false;
    if (type == CoinType.utxo) return true;
    if (type == CoinType.smartChain) return true;

    return false;
  }

  String? get _defaultTrezorAddress {
    if (enabledType != WalletType.trezor) return null;
    if (accounts == null) return null;
    if (accounts!.isEmpty) return null;
    if (accounts!.first.addresses.isEmpty) return null;

    return accounts!.first.addresses.first.address;
  }

  List<HdAddress> nonEmptyHdAddresses() {
    final List<HdAddress>? allAddresses = accounts?.first.addresses;
    if (allAddresses == null) return [];

    final List<HdAddress> nonEmpty = List.from(allAddresses);
    nonEmpty.removeWhere((hdAddress) => hdAddress.balance.spendable <= 0);
    return nonEmpty;
  }

  String? getDerivationPath(String address) {
    final HdAddress? hdAddress = getHdAddress(address);
    return hdAddress?.derivationPath;
  }

  HdAddress? getHdAddress(String? address) {
    if (address == null) return null;
    if (enabledType == WalletType.iguana) return null;
    if (accounts == null || accounts!.isEmpty) return null;

    final List<HdAddress> addresses = accounts!.first.addresses;
    if (address.isEmpty) return null;

    return addresses.firstWhereOrNull(
        (HdAddress hdAddress) => hdAddress.address == address);
  }

  static bool checkSegwitByAbbr(String abbr) => abbr.contains('-segwit');
  static String normalizeAbbr(String abbr) => abbr.replaceAll('-segwit', '');

  @override
  String toString() {
    return 'Coin($abbr);';
  }

  void reset() {
    balance = 0;
    enabledType = null;
    accounts = null;
    state = CoinState.inactive;
  }

  Coin dummyCopyWithoutProtocolData() {
    return Coin(
      type: type,
      abbr: abbr,
      name: name,
      explorerUrl: explorerUrl,
      explorerTxUrl: explorerTxUrl,
      explorerAddressUrl: explorerAddressUrl,
      protocolType: protocolType,
      isTestCoin: isTestCoin,
      coingeckoId: coingeckoId,
      fallbackSwapContract: fallbackSwapContract,
      electrum: electrum,
      nodes: nodes,
      rpcUrls: rpcUrls,
      bchdUrls: bchdUrls,
      priority: priority,
      state: state,
      swapContractAddress: swapContractAddress,
      walletOnly: walletOnly,
      mode: mode,
      usdPrice: usdPrice,
      parentCoin: parentCoin,
      trezorCoin: trezorCoin,
      derivationPath: derivationPath,
      accounts: accounts,
      coinpaprikaId: coinpaprikaId,
      activeByDefault: activeByDefault,
      protocolData: null,
    );
  }
}

String _getExplorerFromJson(Map<String, dynamic> json) {
  return json['explorer_url'] ?? '';
}

String _getExplorerAddressUrlFromJson(Map<String, dynamic> json) {
  final url = json['explorer_address_url'];
  if (url == null || url.isEmpty) {
    return 'address/';
  }
  return url;
}

String _getExplorerTxUrlFromJson(Map<String, dynamic> json) {
  final String? url = json['explorer_tx_url'];
  if (url == null || url.isEmpty) {
    return 'tx/';
  }
  return url;
}

List<CoinNode> _getNodesFromJson(Map<String, dynamic> json) {
  final dynamic nodes = json['nodes'];
  if (nodes is List) {
    return nodes.map<CoinNode>((dynamic n) => CoinNode.fromJson(n)).toList();
  }

  return [];
}

List<CoinNode> _getRpcUrlsFromJson(Map<String, dynamic> json) {
  final dynamic rpcUrls = json['rpc_urls'];
  if (rpcUrls is List) {
    return rpcUrls.map<CoinNode>((dynamic n) => CoinNode.fromJson(n)).toList();
  }

  return [];
}

List<String> _getBchdUrlsFromJson(Map<String, dynamic> json) {
  final dynamic urls = json['bchd_urls'];
  if (urls is List) {
    return List<String>.from(urls);
  }

  return [];
}

List<Electrum> _getElectrumFromJson(Map<String, dynamic> json) {
  final dynamic electrum = json['electrum'];
  if (electrum is List) {
    return electrum
        .map<Electrum>((dynamic item) => Electrum.fromJson(item))
        .toList();
  }

  return [];
}

String _getProtocolType(Map<String, dynamic> coin) {
  return coin['protocol']['type'];
}

ProtocolData? _parseProtocolData(Map<String, dynamic> json) {
  final Map<String, dynamic>? protocolData = json['protocol']['protocol_data'];

  if (protocolData == null ||
      protocolData['platform'] == null ||
      (protocolData['contract_address'] == null &&
          protocolData['platform'] != 'BCH' &&
          protocolData['platform'] != 'tBCH' &&
          protocolData['platform'] != 'IRIS')) return null;
  return ProtocolData.fromJson(protocolData);
}

CoinType? getCoinType(String? jsonType, String coinAbbr) {
  // anchor: protocols support
  for (CoinType value in CoinType.values) {
    switch (value) {
      case CoinType.utxo:
        if (jsonType == 'UTXO') {
          return value;
        } else {
          continue;
        }
      case CoinType.smartChain:
        if (jsonType == 'Smart Chain') {
          return value;
        } else {
          continue;
        }
      case CoinType.erc20:
        if (jsonType == 'ERC-20') {
          return value;
        } else {
          continue;
        }
      case CoinType.bep20:
        if (jsonType == 'BEP-20') {
          return value;
        } else {
          continue;
        }
      case CoinType.qrc20:
        if (jsonType == 'QRC-20') {
          return value;
        } else {
          continue;
        }
      case CoinType.ftm20:
        if (jsonType == 'FTM-20') {
          return value;
        } else {
          continue;
        }
      case CoinType.arb20:
        if (jsonType == 'Arbitrum') {
          return value;
        } else {
          continue;
        }
      case CoinType.etc:
        if (jsonType == 'Ethereum Classic') {
          return value;
        } else {
          continue;
        }
      case CoinType.avx20:
        if (jsonType == 'AVX-20') {
          return value;
        } else {
          continue;
        }
      case CoinType.mvr20:
        if (jsonType == 'Moonriver') {
          return value;
        } else {
          continue;
        }
      case CoinType.hco20:
        if (jsonType == 'HecoChain') {
          return value;
        } else {
          continue;
        }
      case CoinType.plg20:
        if (jsonType == 'Matic') {
          return value;
        } else {
          continue;
        }
      case CoinType.sbch:
        if (jsonType == 'SmartBCH') {
          return value;
        } else {
          continue;
        }
      case CoinType.ubiq:
        if (jsonType == 'Ubiq') {
          return value;
        } else {
          continue;
        }
      case CoinType.hrc20:
        if (jsonType == 'HRC-20') {
          return value;
        } else {
          continue;
        }
      case CoinType.krc20:
        if (jsonType == 'KRC-20') {
          return value;
        } else {
          continue;
        }
      case CoinType.cosmos:
        if (jsonType == 'TENDERMINT' && coinAbbr != 'IRIS') {
          return value;
        } else {
          continue;
        }
      case CoinType.iris:
        if (jsonType == 'TENDERMINTTOKEN' || coinAbbr == 'IRIS') {
          return value;
        } else {
          continue;
        }
      case CoinType.slp:
        if (jsonType == 'SLP') {
          return value;
        } else {
          continue;
        }
    }
  }
  return null;
}

CoinMode _getCoinMode(Map<String, dynamic> json) {
  if ((json['abbr'] as String).contains('-segwit')) {
    return CoinMode.segwit;
  }
  return CoinMode.standard;
}

class ProtocolData {
  ProtocolData({
    required this.platform,
    required this.contractAddress,
  });

  factory ProtocolData.fromJson(Map<String, dynamic> json) => ProtocolData(
        platform: json['platform'],
        contractAddress: json['contract_address'] ?? '',
      );

  String platform;
  String contractAddress;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'platform': platform,
      'contract_address': contractAddress,
    };
  }
}

class CoinNode {
  const CoinNode({required this.url, required this.guiAuth});
  static CoinNode fromJson(Map<String, dynamic> json) => CoinNode(
      url: json['url'],
      guiAuth: (json['gui_auth'] ?? json['komodo_proxy']) ?? false);
  final bool guiAuth;
  final String url;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'gui_auth': guiAuth,
        'komodo_proxy': guiAuth,
      };
}

enum CoinMode { segwit, standard, hw }

enum CoinState {
  inactive,
  activating,
  active,
  suspended,
  hidden,
}
