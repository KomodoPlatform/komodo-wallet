import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:rational/rational.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/performance_analytics/performance_analytics.dart';
import 'package:web_dex/services/logger/get_logger.dart';
import 'package:web_dex/shared/constants.dart';
export 'package:web_dex/shared/utils/extensions/async_extensions.dart';
export 'package:web_dex/shared/utils/prominent_colors.dart';

void copyToClipBoard(BuildContext context, String str) {
  final themeData = Theme.of(context);
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          LocaleKeys.clipBoard.tr(),
          style: themeData.textTheme.bodyLarge!.copyWith(
            color: themeData.brightness == Brightness.dark
                ? themeData.hintColor
                : themeData.primaryColor,
          ),
        ),
      ),
    );
  } catch (_) {}

  Clipboard.setData(ClipboardData(text: str));
}

/// Converts a double value [dv] to a string representation with specified decimal places [fractions].
/// Parameters:
/// - [dv] (double): The input double value to be converted to a string.
/// - [fractions] (int): The number of decimal places to format the double value. Default is 8.
///
/// Return Value:
/// - (String): The formatted string representation of the double value.
///
/// Example Usage:
/// ```dart
/// double inputValue1 = 123.456789;
/// String result1 = doubleToString(inputValue1, 3);
/// print(result1); // Output: "123.457"
/// ```
/// ```dart
/// double inputValue2 = 1000.0;
/// String result2 = doubleToString(inputValue2);
/// print(result2); // Output: "1000"
/// ```
/// unit tests: [testCustomDoubleToString]
String doubleToString(double dv, [int fractions = 8]) {
  final Rational r = Rational.parse(dv.toString());
  if (r.isInteger) {
    return r.toDecimal(scaleOnInfinitePrecision: 24).toStringAsFixed(0);
  }
  String sv = r
      .toDecimal(scaleOnInfinitePrecision: 24)
      .toStringAsFixed(fractions > 20 ? 20 : fractions);
  final dot = sv.indexOf('.');
  // Looks like we already have [cutTrailingZeros]
  sv = sv.replaceFirst(RegExp(r'0+$'), '', dot);
  if (sv.length - 1 == dot) sv = sv.substring(0, dot);
  if (sv == '-0') sv = sv.replaceAll('-', '');
  return sv;
}

/// Converts a map [fract] containing numerator and denominator to a [Rational] value.
/// Parameters:
/// - [fract] (Map<String, dynamic>?): The map containing numerator and denominator values.
///
/// Return Value:
/// - (Rational?): The [Rational] value representing the numerator and denominator,
///                 or null if conversion fails or [fract] is null.
///
/// Example Usage:
/// ```dart
/// Map<String, dynamic> fractionMap = {'numer': 3, 'denom': 4};
/// Rational? result = fract2rat(fractionMap);
/// print(result); // Output: Rational with value 3/4
/// ```
/// ```dart
/// Rational? result = fract2rat(null);
/// print(result); // Output: null
/// ```
/// unit tests: [testRatToFracAndViseVersa]
Rational? fract2rat(Map<String, dynamic>? fract, [bool willLog = true]) {
  if (fract == null) return null;

  try {
    final rat = Rational(
      BigInt.from(double.parse(fract['numer'])),
      BigInt.from(double.parse(fract['denom'])),
    );
    return rat;
  } catch (e) {
    if (willLog) {
      log('Error fract2rat: $e', isError: true);
    }
    return null;
  }
}

/// Converts a [Rational] value [rat] to a map containing numerator and denominator.
///
/// Parameters:
/// - [rat] (Rational?): The [Rational] value to be converted to a map.
/// - [toLog] (bool): Whether to log errors. Default is true.
///
/// Return Value:
/// - (Map<String, dynamic>?): The map containing 'numer' and 'denom' keys and values,
///                            or null if conversion fails or [rat] is null.
///
/// Example Usage:
/// ```dart
/// Rational inputRational = Rational.fromBigInt(BigInt.from(3), BigInt.from(4));
/// Map<String, dynamic>? result = rat2fract(inputRational);
/// print(result); // Output: {'numer': '3', 'denom': '4'}
/// ```
/// ```dart
/// Map<String, dynamic>? result = rat2fract(null);
/// print(result); // Output: null
/// ```
/// unit tests: [testRatToFracAndViseVersa]
Map<String, dynamic>? rat2fract(Rational? rat, [bool toLog = true]) {
  if (rat == null) return null;

  try {
    return <String, dynamic>{
      'numer': rat.numerator.toString(),
      'denom': rat.denominator.toString(),
    };
  } catch (e) {
    if (toLog) {
      log('Error rat2fract: $e', isError: true);
    }
    return null;
  }
}

String getTxExplorerUrl(Coin coin, String txHash) {
  final String explorerUrl = coin.explorerUrl;
  final String explorerTxUrl = coin.explorerTxUrl;
  if (explorerUrl.isEmpty) return '';

  final hash = coin.type == CoinType.iris ? txHash.toUpperCase() : txHash;

  return coin.need0xPrefixForTxHash && !hash.startsWith('0x')
      ? '$explorerUrl${explorerTxUrl}0x$hash'
      : '$explorerUrl$explorerTxUrl$hash';
}

String getAddressExplorerUrl(Coin coin, String address) {
  final String explorerUrl = coin.explorerUrl;
  final String explorerAddressUrl = coin.explorerAddressUrl;
  if (explorerUrl.isEmpty) return '';

  return '$explorerUrl$explorerAddressUrl$address';
}

@Deprecated('Use the Protocol class\'s explorer URL methods')
void viewHashOnExplorer(Coin coin, String address, HashExplorerType type) {
  late String url;
  switch (type) {
    case HashExplorerType.address:
      url = getAddressExplorerUrl(coin, address);
      break;
    case HashExplorerType.tx:
      url = getTxExplorerUrl(coin, address);
      break;
  }
  launchURLString(url);
}

extension AssetExplorerUrls on Asset {
  Uri? txExplorerUrl(String? txHash) {
    return txHash == null ? null : protocol.explorerTxUrl(txHash);
  }

  Uri? addressExplorerUrl(String? address) {
    return address == null ? null : protocol.explorerAddressUrl(address);
  }
}

Future<void> openUrl(Uri uri, {bool? inSeparateTab}) async {
  if (!await canLaunchUrl(uri)) {
    throw Exception('Could not launch $uri');
  }
  await launchUrl(
    uri,
    mode: inSeparateTab == null
        ? LaunchMode.platformDefault
        : inSeparateTab == true
            ? LaunchMode.externalApplication
            : LaunchMode.inAppWebView,
  );
}

Future<void> launchURLString(
  String url, {
  bool? inSeparateTab,
}) async {
  final uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: inSeparateTab == null
          ? LaunchMode.platformDefault
          : inSeparateTab == true
              ? LaunchMode.externalApplication
              : LaunchMode.inAppWebView,
    );
  } else {
    throw 'Could not launch $url';
  }
}

Future<void> log(
  String message, {
  String? path,
  StackTrace? trace,
  bool isError = false,
}) async {
  final timer = Stopwatch()..start();
  // todo(yurii & ivan): to finish stacktrace parsing
  // if (trace != null) {
  //   final String errorTrace = getInfoFromStackTrace(trace);
  //   logger.write('$errorTrace: $errorOrUsefulData');
  // }
  const isTestEnv = isTestMode || kDebugMode;
  if (isTestEnv && isError) {
    // ignore: avoid_print
    print('path: $path');
    // ignore: avoid_print
    print('error: $message');
    if (trace != null) {
      // ignore: avoid_print
      print('trace: $trace');
    }
  }

  try {
    await logger.write(message, path);

    performance.logTimeWritingLogs(timer.elapsedMilliseconds);
  } catch (e) {
    // TODO: replace below with crashlytics reporting or show UI the printed
    // message in a snackbar/banner.
    // ignore: avoid_print
    print(
      'ERROR: Writing logs failed. Exported log files may be incomplete.'
      '\nError message: $e',
    );
  } finally {
    timer.stop();
  }
}

/// Returns the ticker from the coin abbreviation.
///
/// Parameters:
/// - [abbr] (String): The abbreviation of the coin, including suffixes like the
/// coin token type (e.g. 'ETH-ERC20', 'BNB-BEP20') and whether the coin is
/// a test or OLD coin (e.g. 'ETH_OLD', 'BNB-TEST').
///
/// Return Value:
/// - (String): The ticker of the coin, with the suffixes removed.
///
/// Example Usage:
/// ```dart
/// String abbr = 'ETH-ERC20';
///
/// String ticker = abbr2Ticker(abbr);
/// print(ticker); // Output: "ETH"
/// ```
String abbr2Ticker(String abbr) {
  if (_abbr2TickerCache.containsKey(abbr)) return _abbr2TickerCache[abbr]!;
  if (!abbr.contains('-') && !abbr.contains('_')) return abbr;

  const List<String> filteredSuffixes = [
    'ERC20',
    'BEP20',
    'QRC20',
    'FTM20',
    'ARB20',
    'HRC20',
    'MVR20',
    'AVX20',
    'HCO20',
    'PLG20',
    'KRC20',
    'SLP',
    'IBC_IRIS',
    'IBC-IRIS',
    'IRIS',
    'segwit',
    'OLD',
    'IBC_NUCLEUSTEST',
  ];

  // Join the suffixes with '|' to form the regex pattern
  final String regexPattern = '(${filteredSuffixes.join('|')})';

  final String ticker = abbr
      .replaceAll(RegExp('-$regexPattern'), '')
      .replaceAll(RegExp('_$regexPattern'), '');

  _abbr2TickerCache[abbr] = ticker;
  return ticker;
}

/// Returns the ticker from the coin abbreviation with the following suffixes:
/// - 'OLD' for OLD coins.
/// - 'TESTNET' for test coins.
///
/// Parameters:
/// - [abbr] (String): The abbreviation of the coin, including suffixes like the
/// coin token type (e.g. 'ETH-ERC20', 'BNB-BEP20') and whether the coin is
/// a test or OLD coin (e.g. 'ETH_OLD', 'BNB-TEST').
///
/// Return Value:
/// - (String): The ticker of the coin, with the suffixes removed and the
/// suffixes 'OLD' or 'TESTNET' added if present in the abbreviation.
String abbr2TickerWithSuffix(String abbr) {
  final isOldCoin = RegExp(r'[-_]OLD$', caseSensitive: false).hasMatch(abbr);
  final ticker = abbr2Ticker(abbr);
  if (isOldCoin) {
    return '$ticker (OLD)';
  }
  return ticker;
}

final Map<String, String> _abbr2TickerCache = {};

String? getErcTransactionHistoryUrl(Coin coin) {
  final String? address = coin.address;
  if (address == null) return null;

  final String? contractAddress = coin.protocolData?.contractAddress;

  // anchor: protocols support
  switch (coin.type) {
    case CoinType.erc20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        ethUrl,
        ercUrl,
        address,
        contractAddress,
        coin.isTestCoin,
      ); // 'ETH', 'ETHR'

    case CoinType.bep20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        bnbUrl,
        bepUrl,
        address,
        contractAddress,
        coin.isTestCoin,
      ); // 'BNB', 'BNBT'
    case CoinType.ftm20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        ftmUrl,
        ftmTokenUrl,
        address,
        contractAddress,
        coin.isTestCoin,
      ); // 'FTM', 'FTMT'
    case CoinType.arb20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        arbUrl,
        arbTokenUrl,
        address,
        contractAddress,
        coin.isTestCoin,
      ); // 'ARB'
    case CoinType.etc:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        etcUrl,
        '',
        address,
        contractAddress,
        false,
      ); // ETC
    case CoinType.avx20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        avaxUrl,
        avaxTokenUrl,
        address,
        contractAddress,
        coin.isTestCoin,
      ); // AVAX, AVAXT
    case CoinType.mvr20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        mvrUrl,
        mvrTokenUrl,
        address,
        contractAddress,
        coin.isTestCoin,
      ); // MVR
    case CoinType.hco20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        hecoUrl,
        hecoTokenUrl,
        address,
        contractAddress,
        coin.isTestCoin,
      );
    case CoinType.plg20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        maticUrl,
        maticTokenUrl,
        address,
        contractAddress,
        coin.isTestCoin,
      ); // Polygon, MATICTEST
    case CoinType.sbch:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        '',
        '',
        address,
        contractAddress,
        coin.isTestCoin,
      );
    case CoinType.ubiq:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        '',
        '',
        address,
        contractAddress,
        coin.isTestCoin,
      ); // Ubiq
    case CoinType.hrc20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        '',
        '',
        address,
        contractAddress,
        coin.isTestCoin,
      ); // ONE
    case CoinType.krc20:
      return _getErcTransactionHistoryUrl(
        coin.protocolType,
        kcsUrl,
        kcsTokenUrl,
        address,
        contractAddress,
        coin.isTestCoin,
      ); // KCS
    case CoinType.cosmos:
    case CoinType.iris:
    case CoinType.qrc20:
    case CoinType.smartChain:
    case CoinType.utxo:
    case CoinType.slp:
      return null;
  }
}

String _getErcTransactionHistoryUrl(
  String protocolType,
  String protocolUrl,
  String tokenProtocolUrl,
  String address,
  String? contractAddress,
  bool isTestCoin,
) {
  return (protocolType == 'ETH'
          ? '$protocolUrl/$address'
          : '$tokenProtocolUrl/$contractAddress/$address') +
      (isTestCoin ? '&testnet=true' : '');
}

Color getProtocolColor(CoinType type) {
  switch (type) {
    case CoinType.utxo:
      return const Color.fromRGBO(233, 152, 60, 1);
    case CoinType.erc20:
      return const Color.fromRGBO(108, 147, 237, 1);
    case CoinType.smartChain:
      return const Color.fromRGBO(32, 22, 49, 1);
    case CoinType.bep20:
      return const Color.fromRGBO(255, 199, 0, 1);
    case CoinType.qrc20:
      return const Color.fromRGBO(0, 168, 226, 1);
    case CoinType.ftm20:
      return const Color.fromRGBO(25, 105, 255, 1);
    case CoinType.arb20:
      return const Color.fromRGBO(0, 168, 226, 1);
    case CoinType.hrc20:
      return const Color.fromRGBO(29, 195, 219, 1);
    case CoinType.etc:
      return const Color.fromRGBO(16, 185, 129, 1);
    case CoinType.avx20:
      return const Color.fromRGBO(232, 65, 66, 1);
    case CoinType.mvr20:
      return const Color.fromRGBO(242, 183, 5, 1);
    case CoinType.hco20:
      return const Color.fromRGBO(1, 148, 67, 1);
    case CoinType.plg20:
      return const Color.fromRGBO(130, 71, 229, 1);
    case CoinType.sbch:
      return const Color.fromRGBO(117, 222, 84, 1);
    case CoinType.ubiq:
      return const Color.fromRGBO(0, 234, 144, 1);
    case CoinType.krc20:
      return const Color.fromRGBO(66, 229, 174, 1);
    case CoinType.cosmos:
      return const Color.fromRGBO(60, 60, 85, 1);
    case CoinType.iris:
      return const Color.fromRGBO(136, 87, 138, 1);
    case CoinType.slp:
      return const Color.fromRGBO(134, 184, 124, 1);
  }
}

bool hasTxHistorySupport(Coin coin) {
  if (coin.enabledType == WalletType.trezor) {
    return true;
  }
  switch (coin.type) {
    case CoinType.sbch:
    case CoinType.ubiq:
    case CoinType.hrc20:
      return false;
    case CoinType.krc20:
    case CoinType.cosmos:
    case CoinType.iris:
    case CoinType.utxo:
    case CoinType.erc20:
    case CoinType.smartChain:
    case CoinType.bep20:
    case CoinType.qrc20:
    case CoinType.ftm20:
    case CoinType.arb20:
    case CoinType.etc:
    case CoinType.avx20:
    case CoinType.mvr20:
    case CoinType.hco20:
    case CoinType.plg20:
    case CoinType.slp:
      return true;
  }
}

String getNativeExplorerUrlByCoin(Coin coin, String? address) {
  final bool hasSupport = hasTxHistorySupport(coin);
  assert(!hasSupport);

  switch (coin.type) {
    case CoinType.sbch:
    case CoinType.iris:
      return '${coin.explorerUrl}address/${coin.address}';
    case CoinType.cosmos:
      return '${coin.explorerUrl}account/${coin.address}';

    case CoinType.utxo:
    case CoinType.smartChain:
    case CoinType.erc20:
    case CoinType.bep20:
    case CoinType.qrc20:
    case CoinType.ftm20:
    case CoinType.arb20:
    case CoinType.avx20:
    case CoinType.mvr20:
    case CoinType.hco20:
    case CoinType.plg20:
    case CoinType.etc:
    case CoinType.hrc20:
    case CoinType.ubiq:
    case CoinType.krc20:
    case CoinType.slp:
      return '${coin.explorerUrl}address/${address ?? coin.address}';
  }
}

String get themeAssetPostfix => theme.mode == ThemeMode.dark ? '_dark' : '';

void rebuildAll(BuildContext? context) {
  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  ((materialPageContext ?? context) as Element).visitChildren(rebuild);
}

int get nowMs => DateTime.now().millisecondsSinceEpoch;

String? assertString(dynamic value) {
  if (value == null) return null;

  switch (value.runtimeType) {
    case int:
    case double:
      return value.toString();
    default:
      return value as String?;
  }
}

int? assertInt(dynamic value) {
  if (value == null) return null;

  switch (value.runtimeType) {
    case String:
      return int.parse(value as String);
    default:
      return value as int?;
  }
}

double assertDouble(dynamic value) {
  if (value == null) return double.nan;

  switch (value.runtimeType) {
    case double:
      return value as double;
    case int:
      return (value as int).toDouble();
    case String:
      return double.tryParse(value as String) ?? double.nan;
    case bool:
      return (value as bool) ? 1.0 : 0.0;
    case num:
      return (value as num).toDouble();
    default:
      try {
        return double.parse(value.toString());
      } catch (e, s) {
        log('Error converting to double: $e', trace: s, isError: true);
        return double.nan;
      }
  }
}

Future<void> pauseWhile(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final int startMs = nowMs;
  bool timedOut = false;
  while (condition() && !timedOut) {
    await Future<dynamic>.delayed(const Duration(milliseconds: 10));
    timedOut = nowMs - startMs > timeout.inMilliseconds;
  }
}

enum HashExplorerType {
  address,
  tx,
}

Asset getSdkAsset(KomodoDefiSdk sdk, String abbr) {
  // ignore: deprecated_member_use
  return sdk.assets.assetsFromTicker(abbr).single;
}
