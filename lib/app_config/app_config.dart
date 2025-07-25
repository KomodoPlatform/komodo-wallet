import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

const String mmRpcVersion = '2.0';
// issue https://github.com/flutter/flutter/issues/19462#issuecomment-478284020
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
const double maxScreenWidth = 1273;
const double mainLayoutPadding = 29;
const double appBarHeight = 70;
const int scaleOnInfinitePrecision = 20; // ETH has 18 decimals, so use more
const String allWalletsStorageKey = 'all-wallets';
const String defaultDexCoin = 'KMD';
const String trezorWalletNamePrefix = 'my trezor';
const List<Locale> localeList = [Locale('en')];
const String assetsPath = 'assets';
const String coinsAssetsPath = 'packages/komodo_defi_framework/assets';

final Uri discordSupportChannelUrl = Uri.parse(
    'https://discord.com/channels/412898016371015680/429676282196787200');
final Uri discordInviteUrl = Uri.parse('https://komodoplatform.com/discord');

/// Const to define if Bitrefill integration is enabled in the app.
const bool isBitrefillIntegrationEnabled = false;

/// Const to define whether to show trading warning dialogs and notices.
/// This can be used to control the display of trading-related warnings
/// throughout the application.
///
///! You are solely responsible for any losses/damage that may occur due to
///! compliance issues, bugs, or other unforeseen circumstances. Komodo
///! Platform and its legal entities do not condone the use of this app for
///! trading purposes where it is not legally compliant.
const bool kShowTradingWarning = false;

const Duration kPerformanceLogInterval = Duration(minutes: 1);

// This information is here because it is not contextual and is branded.
// Names of their own are not localized. Also, the application is initialized before
// the localization package is initialized.
String get appTitle => 'Komodo Wallet | Non-Custodial Multi-Coin Wallet & DEX';
String get appShortTitle => 'Komodo Wallet';

Map<String, int> priorityCoinsAbbrMap = {
  // KMD always has highest priority (special case for Komodo ecosystem)
  'KMD': 1000,

  // Top 10 cryptocurrencies by market cap (as of current data)
  // Rank 1: Bitcoin (~$2.21 trillion)
  'BTC': 100,
  'BTC-segwit': 100,

  // Rank 2: Ethereum (~$335 billion)
  'ETH': 90,

  // Rank 3: Tether (~$159 billion)
  'USDT': 80,
  'USDT-ERC20': 80,
  'USDT-PLG20': 80,
  'USDT-BEP20': 80,

  // Rank 4: XRP (~$145 billion)
  'XRP': 70,

  // Rank 5: BNB (~$93 billion)
  'BNB': 60,

  // Rank 6: Solana (~$84 billion)
  'SOL': 50,

  // Rank 7: USD Coin (~$63 billion)
  'USDC': 40,
  'USDC-ERC20': 40,
  'USDC-PLG20': 40,
  'USDC-BEP20': 40,

  // Rank 8: TRON (~$27.5 billion)
  'TRX': 30,

  // Rank 9: Dogecoin (~$27.1 billion)
  'DOGE': 20,

  // Rank 10: Cardano (~$22.3 billion)
  'ADA': 10,

  // Additional coins with higher than default priority
  'LTC-segwit': 5, // Litecoin (popular)
  'LTC': 5,

  // All other coins get default priority (0)
};

/// List of coins that are excluded from the list of coins displayed on the
/// coin lists (e.g. wallet page, coin selection dropdowns, etc.)
const Set<String> excludedAssetList = {
  'ADEXBSCT',
  'ADEXBSC',
  'BRC',
  'WID',
  'EPC',
  'CFUN',
  'ENT',
  'PLY',
  'ILNSW-PLG20',
  'FENIX',
  'AWR',
  'BOT',
  // Pirate activation params are not yet implemented, so we need to
  // exclude it from the list of coins for now.
  'ARRR',
  'ZOMBIE',
  'SMTF-v2',
  'SFUSD',
  'VOTE2023',
  'RICK',
  'MORTY',

  // NFT v2 coins: https://github.com/KomodoPlatform/coins/pull/1061 will be
  // used in the background, so users do not need to see them.
  'NFT_ETH',
  'NFT_AVAX',
  'NFT_BNB',
  'NFT_FTM',
  'NFT_MATIC',
};

/// Some coins returned by the Banxa API are returning errors when attempting
/// to create an order. This is a temporary workaround to filter out those coins
/// until the issue is resolved.
const banxaUnsupportedCoinsList = [
  'APE', // chain not configured for APE
  'AVAX', // avax & bep20 - invalid wallet address error
  'DOT', // bep20 - invalid wallet address error
  'FIL', // bep20 - invalid wallet address error
  'ONE', // invalid wallet address error (one**** (native) format expected)
  'TON', // erc20 - invalid wallet address error
  'TRX', // bep20 - invalid wallet address error
  'XML', // invalid wallet address error
];

const rampUnsupportedCoinsList = [
  'ONE', // invalid wallet address error (one**** format expected)
];

// Assets in wallet-only mode on app level,
// global wallet-only assets are defined in coins config files.
const List<String> appWalletOnlyAssetList = [
  'BET',
  'BOTS',
  'CRYPTO',
  'DEX',
  'HODL',
  'JUMBLR',
  'MGW',
  'MSHARK',
  'PANGEA',
  'REVS',
  'SUPERNET',
];

/// Coins that are enabled by default on restore from seed or registration.
/// This will not affect existing wallets.
List<String> get enabledByDefaultCoins => [
      'KMD', // Always included (Komodo ecosystem)
      'BTC-segwit', // Bitcoin (Rank 1, ~$2.21T market cap)
      'ETH', // Ethereum (Rank 2, ~$335B market cap)
      'BNB', // Binance Coin (Rank 5, ~$93B market cap)
      'DOGE', // Dogecoin (Rank 9, ~$27.1B market cap)
      'LTC-segwit', // Litecoin (popular, has segwit support)
      'USDT-ERC20', // Tether on Ethereum (most common stablecoin)
      'XRP-ERC20', // XRP (Rank 4, ~$145B market cap)
      if (kDebugMode) 'DOC',
      if (kDebugMode) 'MARTY',
    ];

List<String> get coinsWithFaucet => ['RICK', 'MORTY', 'DOC', 'MARTY'];

const String logsDbName = 'logs';
const String appFolder = 'KomodoWallet';

Future<String> get applicationDocumentsDirectory async => kIsWeb
    ? appFolder
    : '${(await getApplicationDocumentsDirectory()).path}/$appFolder';
