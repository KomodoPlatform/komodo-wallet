RegExp numberRegExp = RegExp('^\$|^(0|([1-9][0-9]{0,12}))([.,]{1}[0-9]{0,8})?');
RegExp emailRegex = RegExp(
  r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
);
const int decimalRange = 8;

// stored app preferences
const String storedSettingsKey = '_atomicDexStoredSettings';
const String storedAnalyticsSettingsKey = 'analytics_settings';
const String storedMarketMakerSettingsKey = 'market_maker_settings';

// anchor: protocols support
const String ercTxHistoryUrl = 'https://etherscan-proxy.komodo.earth/api';
const String ethUrl = '$ercTxHistoryUrl/v1/eth_tx_history';
const String ercUrl = '$ercTxHistoryUrl/v2/erc_tx_history';
const String bnbUrl = '$ercTxHistoryUrl/v1/bnb_tx_history';
const String bepUrl = '$ercTxHistoryUrl/v2/bep_tx_history';
const String ftmUrl = '$ercTxHistoryUrl/v1/ftm_tx_history';
const String ftmTokenUrl = '$ercTxHistoryUrl/v2/ftm_tx_history';
const String arbUrl = '$ercTxHistoryUrl/v1/arbitrum_tx_history';
const String arbTokenUrl = '$ercTxHistoryUrl/v2/arbitrum_tx_history';
const String etcUrl = '$ercTxHistoryUrl/v1/etc_tx_history';
const String avaxUrl = '$ercTxHistoryUrl/v1/avx_tx_history';
const String avaxTokenUrl = '$ercTxHistoryUrl/v2/avx_tx_history';
const String mvrUrl = '$ercTxHistoryUrl/v1/moonriver_tx_history';
const String mvrTokenUrl = '$ercTxHistoryUrl/v2/moonriver_tx_history';
const String hecoUrl = '$ercTxHistoryUrl/v1/heco_tx_history';
const String hecoTokenUrl = '$ercTxHistoryUrl/v2/heco_tx_history';
const String maticUrl = '$ercTxHistoryUrl/v1/plg_tx_history';
const String maticTokenUrl = '$ercTxHistoryUrl/v2/plg_tx_history';
const String kcsUrl = '$ercTxHistoryUrl/v1/kcs_tx_history';
const String kcsTokenUrl = '$ercTxHistoryUrl/v2/kcs_tx_history';
const String txByHashUrl = '$ercTxHistoryUrl/v1/transactions_by_hash';

const String updateCheckerEndpoint = 'https://komodo.earth/adexwebversion';
final Uri feedbackUrl = Uri.parse('https://komodo.earth:8181/webform/');
const int feedbackMaxLength = 1000;
const int contactDetailsMaxLength = 100;
final RegExp discordUsernameRegex = RegExp(r'^[a-zA-Z0-9._]{2,32}$');
final RegExp telegramUsernameRegex = RegExp(r'^[a-zA-Z0-9_]{5,32}$');
final RegExp matrixIdRegex =
    RegExp(r'^@[a-zA-Z0-9._=-]+:[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
final Uri pricesUrlV3 = Uri.parse(
  'https://defi-stats.komodo.earth/api/v3/prices/tickers_v2?expire_at=60',
);

const int millisecondsIn24H = 86400000;

const bool isTestMode = bool.fromEnvironment(
  'testing_mode',
  defaultValue: false,
);
const String moralisProxyUrl = 'https://moralis-proxy.komodo.earth';
const String nftAntiSpamUrl = 'https://nft.antispam.dragonhound.info';

const String geoBlockerApiUrl =
    'https://komodo-wallet-bouncer.komodoplatform.com';
const String tradingBlacklistUrl =
    'https://defi-stats.komodo.earth/api/v3/utils/blacklist';
