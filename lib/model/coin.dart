import 'package:collection/collection.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
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
    required this.id,
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
  final AssetId id;
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

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset multi-address support instead. The wallet now works with multiple addresses per account.')
  String? address;

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset account management instead.')
  List<HdAccount>? accounts;

  final double _balance;
  final String? _swapContractAddress;
  String? fallbackSwapContract;

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s WalletManager to determine wallet type.')
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

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset.sendableBalance instead. This value is not updated after initial load and may be inaccurate.')
  double sendableBalance = 0;

  @Deprecated('$_urgentDeprecationNotice Use the balance manager from the SDK. This balance value is not updated after initial load and may be inaccurate.')
  double get balance {
    switch (enabledType) {
      case WalletType.trezor:
        return _totalHdBalance ?? 0.0;
      default:
        return _balance;
    }
  }

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset balance tracking instead. This balance value is not updated after initial load and may be inaccurate.')
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

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset price and balance methods instead. This value uses potentially outdated balance and price information.')
  double? get usdBalance {
    if (usdPrice == null) return null;
    if (balance == 0) return 0;

    return calculateUsdAmount(balance.toDouble());
  }

  String amountToFormattedUsd(double amount) {
    if (usdPrice == null) return '\$0.00';
    return '\$${formatAmt(calculateUsdAmount(amount))}';
  }

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset balance methods. This getter uses outdated balance information.')
  String get getFormattedUsdBalance => amountToFormattedUsd(balance);

  String get typeName => getCoinTypeName(type);
  String get typeNameWithTestnet => typeName + (isTestCoin ? ' (TESTNET)' : '');

  bool get isIrisToken => protocolType == 'TENDERMINTTOKEN';

  bool get need0xPrefixForTxHash => isErcType;

  bool get isErcType => protocolType == 'ERC20' || protocolType == 'ETH';

  bool get isTxMemoSupported =>
      type == CoinType.iris || type == CoinType.cosmos;

  @Deprecated('TODO: Adapt SDK to cater for this use case and remove this method.')
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

  @Deprecated('TODO: Adapt SDK to cater for this use case and remove this method.')
  String? get _defaultTrezorAddress {
    if (enabledType != WalletType.trezor) return null;
    if (accounts == null) return null;
    if (accounts!.isEmpty) return null;
    if (accounts!.first.addresses.isEmpty) return null;

    return accounts!.first.addresses.first.address;
  }

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset address management instead. This value is not updated after initial load and may be inaccurate.')
  List<HdAddress> nonEmptyHdAddresses() {
    final List<HdAddress>? allAddresses = accounts?.first.addresses;
    if (allAddresses == null) return [];

    final List<HdAddress> nonEmpty = List.from(allAddresses);
    nonEmpty.removeWhere((hdAddress) => hdAddress.balance.spendable <= 0);
    return nonEmpty;
  }

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset derivation methods instead. This method does not work for multiple addresses per coin.')
  String? getDerivationPath(String address) {
    final HdAddress? hdAddress = getHdAddress(address);
    return hdAddress?.derivationPath;
  }

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset address management instead. This method does not work for multiple addresses per coin.')
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

  @Deprecated('$_urgentDeprecationNotice Use the SDK\'s Asset state management instead.')
  void reset() {
    enabledType = null;
    accounts = null;
    state = CoinState.inactive;
  }

  Coin dummyCopyWithoutProtocolData() {
    return Coin(
      type: type,
      abbr: abbr,
      id: assetId,
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

  AssetId get assetId => AssetId(
        id: abbr,
        name: name,
        symbol: AssetSymbol(
          assetConfigId: abbr,
          coinGeckoId: coingeckoId,
          coinPaprikaId: coinpaprikaId,
        ),
        chainId: AssetChainId(chainId: 0),
        derivationPath: derivationPath ?? '',
        subClass: type.toCoinSubClass(),
      );

  Coin copyWith({
    CoinType? type,
    String? abbr,
    AssetId? id,
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
    bool? isCustomCoin,
  }) {
    return Coin(
      type: type ?? this.type,
      abbr: abbr ?? this.abbr,
      id: id ?? this.id,
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
      isCustomCoin: isCustomCoin ?? this.isCustomCoin,
    )
      ..address = address ?? this.address
      ..enabledType = enabledType ?? this.enabledType
      ..sendableBalance = sendableBalance ?? this.sendableBalance;
  }
}

extension LegacyCoinToSdkAsset on Coin {
  Asset toSdkAsset(KomodoDefiSdk sdk) => getSdkAsset(sdk, abbr);
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

const String _urgentDeprecationNotice ='(URGENT) This must be fixed before the next release.';