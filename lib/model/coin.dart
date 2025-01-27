import 'package:collection/collection.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/model/cex_price.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/model/hd_account/hd_account.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/formatters.dart';

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
    required this.logoImageUrl,
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
    this.isCustomCoin = false,
    required String? swapContractAddress,
    required bool walletOnly,
    required this.mode,
    double? balance,
  })  : _swapContractAddress = swapContractAddress,
        _walletOnly = walletOnly,
        _balance = balance ?? 0;

  final String abbr;
  final String name;
  final String? logoImageUrl;
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
  bool isCustomCoin;
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
        (HdAddress hdAddress) => hdAddress.address == address);
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
      isCustomCoin: isCustomCoin,
      logoImageUrl: logoImageUrl,
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

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      type: CoinType.values.firstWhere((value) => value == json['type']),
      abbr: json['abbr'],
      name: json['name'],
      logoImageUrl: json['logo_image_url'],
      explorerUrl: json['explorer_url'],
      explorerTxUrl: json['explorer_tx_url'],
      explorerAddressUrl: json['explorer_address_url'],
      protocolType: json['protocol_type'],
      protocolData: json['protocol_data'] == null
          ? null
          : ProtocolData.fromJson(json['protocol_data']),
      isTestCoin: json['is_test_coin'],
      coingeckoId: json['coingecko_id'],
      fallbackSwapContract: json['fallback_swap_contract'],
      priority: json['priority'],
      state: CoinState.values
              .firstWhereOrNull((value) => value.name == json['state']) ??
          CoinState.inactive,
      decimals: json['decimals'],
      parentCoin: json['parent_coin'] == null
          ? null
          : Coin.fromJson(json['parent_coin']),
      derivationPath: json['derivation_path'],
      accounts: json['accounts'] == null
          ? null
          : List<HdAccount>.from(
              json['accounts'].map((account) => HdAccount.fromJson(account))),
      coinpaprikaId: json['coinpaprika_id'],
      activeByDefault: json['active_by_default'],
      swapContractAddress: json['swap_contract_address'],
      walletOnly: json['wallet_only'],
      mode: CoinMode.values
              .firstWhereOrNull((value) => value.name == json['mode']) ??
          CoinMode.standard,
      isCustomCoin: true,
    )..enabledType = WalletType.values
        .firstWhereOrNull((value) => value.name == json['enabled_type']);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'abbr': abbr,
      'name': name,
      'logo_image_url': logoImageUrl,
      'explorer_url': explorerUrl,
      'explorer_tx_url': explorerTxUrl,
      'explorer_address_url': explorerAddressUrl,
      'protocol_type': protocolType,
      'protocol_data': protocolData?.toJson(),
      'is_test_coin': isTestCoin,
      'coingecko_id': coingeckoId,
      'fallback_swap_contract': fallbackSwapContract,
      'priority': priority,
      'state': state.name,
      'decimals': decimals,
      'parent_coin': parentCoin?.toJson(),
      'derivation_path': derivationPath,
      'accounts':
          accounts?.map((HdAccount account) => account.toJson()).toList(),
      'usd_price': usdPrice?.toJson(),
      'coinpaprika_id': coinpaprikaId,
      'active_by_default': activeByDefault,
      'swap_contract_address': swapContractAddress,
      'wallet_only': walletOnly,
      'mode': mode.name,
      'address': address,
      'enabled_type': enabledType?.name,
      'sendable_balance': sendableBalance,
    };
  }

  Coin copyWith({
    CoinType? type,
    String? abbr,
    String? name,
    String? explorerUrl,
    String? explorerTxUrl,
    String? explorerAddressUrl,
    String? protocolType,
    String? logoImageUrl,
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
      logoImageUrl: logoImageUrl ?? this.logoImageUrl,
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

extension CoinListExtension on List<Coin> {
  Map<String, Coin> toMap() {
    return Map.fromEntries(map((coin) => MapEntry(coin.abbr, coin)));
  }
}
