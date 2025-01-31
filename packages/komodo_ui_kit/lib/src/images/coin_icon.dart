import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const coinImagesFolder = 'assets/coin_icons/png/';
const mediaCdnUrl = 'https://komodoplatform.github.io/coins/icons/';

final Map<String, bool> _assetExistenceCache = {};
final Map<String, bool> _cdnExistenceCache = {};
List<String>? _cachedFileList;

String _getImagePath(String abbr) {
  final fileName = abbr2Ticker(abbr).toLowerCase();
  return '$coinImagesFolder$fileName.png';
}

String _getCdnUrl(String abbr) {
  final fileName = abbr2Ticker(abbr).toLowerCase();
  return '$mediaCdnUrl$fileName.png';
}

Future<List<String>> _getFileList() async {
  if (_cachedFileList == null) {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      _cachedFileList = manifestMap.keys
          .where((String key) => key.startsWith(coinImagesFolder))
          .toList();
    } catch (e) {
      debugPrint('Error loading asset manifest: $e');
      _cachedFileList = [];
    }
  }
  return _cachedFileList!;
}

Future<bool> checkIfAssetExists(String abbr) async {
  final filePath = _getImagePath(abbr);

  if (_assetExistenceCache.containsKey(filePath)) {
    return _assetExistenceCache[filePath]!;
  }

  try {
    final fileList = await _getFileList();
    final exists = fileList.contains(filePath);

    if (exists) {
      try {
        await rootBundle.load(filePath);
        _assetExistenceCache[filePath] = true;
      } catch (e) {
        debugPrint('Asset $filePath found in manifest but failed to load: $e');
        _assetExistenceCache[filePath] = false;
      }
    } else {
      _assetExistenceCache[filePath] = false;
    }

    return _assetExistenceCache[filePath]!;
  } catch (e) {
    debugPrint('Error checking if asset exists for $abbr: $e');
    _assetExistenceCache[filePath] = false;
    return false;
  }
}

class CoinIcon extends StatelessWidget {
  const CoinIcon(
    this.coinAbbr, {
    this.size = 20,
    this.suspended = false,
    super.key,
  });

  /// Convenience constructor for creating a coin icon from a symbol aka
  /// abbreviation. This avoids having to call [abbr2Ticker] manually.
  CoinIcon.ofSymbol(
    String symbol, {
    this.size = 20,
    this.suspended = false,
    super.key,
  }) : coinAbbr = abbr2Ticker(symbol);

  final String coinAbbr;
  final double size;
  final bool suspended;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: suspended ? 0.4 : 1,
      child: SizedBox.square(
        dimension: size,
        child: CoinIconResolverWidget(
          key: Key(coinAbbr),
          coinAbbr: coinAbbr,
          size: size,
        ),
      ),
    );
  }

  void clearAssetCaches() {
    _assetExistenceCache.clear();
    _cdnExistenceCache.clear();
    _cachedFileList = null;
  }

  /// Pre-loads the coin icon image into the cache.
  ///
  /// Whilst ignoring exceptions is generally discouraged, this method allows
  /// this because it may be expected that some coin icons are not available.
  ///
  /// Use with caution when pre-loading many images on resource-constrained
  /// devices. See [precacheImage]'s documentation for more information.
  static Future<void> precacheCoinIcon(
    BuildContext context,
    String abbr, {
    bool throwExceptions = false,
  }) async {
    try {
      bool? assetExists, cdnExists;

      final filePath = _getImagePath(abbr);
      final assetImage = AssetImage(filePath);
      final cdn = _getCdnUrl(abbr);
      final cdnImage = NetworkImage(cdn);

      assetExists = true;
      await precacheImage(
        assetImage,
        context,
        onError: (e, stackTrace) {
          assetExists = false;

          if (throwExceptions) {
            throw Exception('Failed to pre-cache image for coin $abbr: $e');
          }
        },
      );
      if (context.mounted) {
        cdnExists = true;
        await precacheImage(
          cdnImage,
          context,
          onError: (e, stackTrace) {
            cdnExists = false;

            if (throwExceptions) {
              throw Exception('Failed to pre-cache image for coin $abbr: $e');
            }
          },
        );
      }

      _assetExistenceCache[filePath] = assetExists ?? false;
      if (cdnExists != null) _cdnExistenceCache[abbr] = cdnExists!;
    } catch (e) {
      debugPrint('Error in precacheCoinIcon for $abbr: $e');
      if (throwExceptions) rethrow;
    }
  }
}

class CoinIconResolverWidget extends StatelessWidget {
  const CoinIconResolverWidget({
    super.key,
    required this.coinAbbr,
    required this.size,
  });

  final String coinAbbr;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Check local asset first
    final filePath = _getImagePath(coinAbbr);

    // if (await checkIfAssetExists(coinAbbr)) {

    _assetExistenceCache[filePath] = true;
    return Image.asset(
      filePath,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        _assetExistenceCache[filePath] = false;

        _cdnExistenceCache[coinAbbr] ??= true;
        return Image.network(
          _getCdnUrl(coinAbbr),
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            _cdnExistenceCache[coinAbbr] = false;
            return Icon(Icons.monetization_on_outlined, size: size);
          },
        );
      },
    );
  }
}

// DUPLICATED FROM MAIN PROJECT in `lib/shared/utils/utils.dart`.
// NB: ENSURE IT STAYS IN SYNC.

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

  String regexPattern = '(${filteredSuffixes.join('|')})';

  String ticker = abbr
      .replaceAll(RegExp('-$regexPattern'), '')
      .replaceAll(RegExp('_$regexPattern'), '');

  _abbr2TickerCache[abbr] = ticker;
  return ticker;
}

final Map<String, String> _abbr2TickerCache = {};
