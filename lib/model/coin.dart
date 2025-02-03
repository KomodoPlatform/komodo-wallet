import 'package:collection/collection.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/model/cex_price.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';
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
    required this.priority,
    required this.state,
    this.decimals = 8,
    this.parentCoin,
    this.derivationPath,
    this.accounts,
    this.usdPrice,
    this.coinpaprikaId,
    this.activeByDefault = false,
    required String? swapContractAddress,
    required bool walletOnly,
    required this.mode,
    double? balance,
  })  : _swapContractAddress = swapContractAddress,
        _walletOnly = walletOnly,
        _balance = balance ?? 0;

  final String abbr;
  final String name;
  final String? coingeckoId;
  final String? coinpaprikaId;
  final CoinType type;
  final bool activeByDefault;
  final String protocolType;
  final ProtocolData? protocolData;
  final String explorerUrl;
  final String explorerTxUrl;
  final String explorerAddressUrl;
  final String? derivationPath;
  final int decimals;
  CexPrice? usdPrice;
  final bool isTestCoin;
  String? address;
  List<HdAccount>? accounts;
  final double _balance;
  final String? _swapContractAddress;
  String? fallbackSwapContract;
  WalletType? enabledType;
  final bool _walletOnly;
  final int priority;
  Coin? parentCoin;
  final CoinMode mode;
  CoinState state;

  bool get walletOnly => _walletOnly || appWalletOnlyAssetList.contains(abbr);

  String? get swapContractAddress =>
      _swapContractAddress ?? parentCoin?.swapContractAddress;
  bool get isSuspended => state == CoinState.suspended;
  bool get isActive => state == CoinState.active;
  bool get isActivating => state == CoinState.activating;
  bool get isInactive => state == CoinState.inactive;

  double sendableBalance = 0;

  @Deprecated('Use the balance manager from the SDK')
  double get balance {
    switch (enabledType) {
      case WalletType.trezor:
        return _totalHdBalance ?? 0.0;
      default:
        return _balance;
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

  double calculateUsdAmount(double amount) {
    if (usdPrice == null) return 0;
    return amount * usdPrice!.price;
  }

  double? get usdBalance {
    if (usdPrice == null) return null;
    if (balance == 0) return 0;

    return calculateUsdAmount(balance.toDouble());
  }

  String amountToFormattedUsd(double amount) {
    if (usdPrice == null) return '\$0.00';
    return '\$${formatAmt(calculateUsdAmount(amount))}';
  }

  String get getFormattedUsdBalance => amountToFormattedUsd(balance);

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
      (HdAddress hdAddress) => hdAddress.address == address,
    );
  }

  static bool checkSegwitByAbbr(String abbr) => abbr.contains('-segwit');
  static String normalizeAbbr(String abbr) => abbr.replaceAll('-segwit', '');

  @override
  String toString() {
    return 'Coin($abbr);';
  }

  void reset() {
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
      priority: priority,
      state: state,
      swapContractAddress: swapContractAddress,
      walletOnly: walletOnly,
      mode: mode,
      usdPrice: usdPrice,
      parentCoin: parentCoin,
      derivationPath: derivationPath,
      accounts: accounts,
      coinpaprikaId: coinpaprikaId,
      activeByDefault: activeByDefault,
      protocolData: null,
    );
  }

  Coin copyWith({
    CoinType? type,
    String? abbr,
    String? name,
    String? explorerUrl,
    String? explorerTxUrl,
    String? explorerAddressUrl,
    String? protocolType,
    ProtocolData? protocolData,
    bool? isTestCoin,
    String? coingeckoId,
    String? fallbackSwapContract,
    int? priority,
    CoinState? state,
    int? decimals,
    Coin? parentCoin,
    String? derivationPath,
    List<HdAccount>? accounts,
    CexPrice? usdPrice,
    String? coinpaprikaId,
    bool? activeByDefault,
    String? swapContractAddress,
    bool? walletOnly,
    CoinMode? mode,
    String? address,
    WalletType? enabledType,
    double? balance,
    double? sendableBalance,
  }) {
    return Coin(
      type: type ?? this.type,
      abbr: abbr ?? this.abbr,
      name: name ?? this.name,
      explorerUrl: explorerUrl ?? this.explorerUrl,
      explorerTxUrl: explorerTxUrl ?? this.explorerTxUrl,
      explorerAddressUrl: explorerAddressUrl ?? this.explorerAddressUrl,
      protocolType: protocolType ?? this.protocolType,
      protocolData: protocolData ?? this.protocolData,
      isTestCoin: isTestCoin ?? this.isTestCoin,
      coingeckoId: coingeckoId ?? this.coingeckoId,
      fallbackSwapContract: fallbackSwapContract ?? this.fallbackSwapContract,
      priority: priority ?? this.priority,
      state: state ?? this.state,
      decimals: decimals ?? this.decimals,
      parentCoin: parentCoin ?? this.parentCoin,
      derivationPath: derivationPath ?? this.derivationPath,
      accounts: accounts ?? this.accounts,
      usdPrice: usdPrice ?? this.usdPrice,
      coinpaprikaId: coinpaprikaId ?? this.coinpaprikaId,
      activeByDefault: activeByDefault ?? this.activeByDefault,
      swapContractAddress: swapContractAddress ?? _swapContractAddress,
      walletOnly: walletOnly ?? _walletOnly,
      mode: mode ?? this.mode,
      balance: balance ?? _balance,
    )
      ..address = address ?? this.address
      ..enabledType = enabledType ?? this.enabledType
      ..sendableBalance = sendableBalance ?? this.sendableBalance;
  }
}

extension LegacyCoinToSdkAsset on Coin {
  Asset toSdkAsset(KomodoDefiSdk sdk) => getSdkAsset(sdk, abbr);
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
        guiAuth: (json['gui_auth'] ?? json['komodo_proxy']) ?? false,
      );
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

extension CoinListExtension on List<Coin> {
  Map<String, Coin> toMap() {
    return Map.fromEntries(map((coin) => MapEntry(coin.abbr, coin)));
  }
}
