import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// NB: ENSURE IT STAYS IN SYNC WITH MAIN PROJECT in `lib/src/utils/utils.dart`.
const coinImagesFolder = 'assets/coin_icons/png/';

final Map<String, bool> _assetExistenceCache = {};
List<String>? _cachedFileList;

String _getImagePath(String abbr) {
  final fileName = abbr2Ticker(abbr).toLowerCase();
  return '$coinImagesFolder$fileName.png';
}

Future<List<String>> _getFileList() async {
  if (_cachedFileList == null) {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifestMap = json.decode(manifestContent);
    _cachedFileList = manifestMap.keys
        .where((String key) => key.startsWith(coinImagesFolder))
        .toList();
  }
  return _cachedFileList!;
}

Future<bool> checkIfAssetExists(String abbr) async {
  final filePath = _getImagePath(abbr);

  if (!_assetExistenceCache.containsKey(filePath)) {
    final fileList = await _getFileList();
    _assetExistenceCache[filePath] = fileList.contains(filePath);
  }

  return _assetExistenceCache[filePath]!;
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
  ///
  ///
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
    final placeHolder = Center(child: Icon(Icons.monetization_on, size: size));

    return Opacity(
      opacity: suspended ? 0.4 : 1,
      child: SizedBox.square(
        dimension: size,
        child: _maybeAssetExists() == true
            ? _knownImage()
            : _maybeAssetExists() == false
                ? placeHolder
                : FutureBuilder<Image?>(
                    future: _getImage(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!;
                      } else {
                        return placeHolder;
                      }
                    },
                  ),
      ),
    );
  }

  /// Returns null if the asset existence is unknown.
  /// Returns true if the asset exists.
  /// Returns false if the asset does not exist.
  bool? _maybeAssetExists() => _assetExistenceCache[_getImagePath(coinAbbr)];

  Image _knownImage() => Image.asset(
        _getImagePath(coinAbbr),
        filterQuality: FilterQuality.high,
      );

  Future<Image?> _getImage() async {
    if ((await checkIfAssetExists(coinAbbr)) == false) {
      return null;
    }

    return _knownImage();
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
    final filePath = _getImagePath(abbr);
    final image = AssetImage(filePath);
    await precacheImage(
      image,
      context,
      onError: !throwExceptions
          ? null
          : (e, _) =>
              throw Exception('Failed to pre-cache image for coin $abbr: $e'),
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

  // Join the suffixes with '|' to form the regex pattern
  String regexPattern = '(${filteredSuffixes.join('|')})';

  String ticker = abbr
      .replaceAll(RegExp('-$regexPattern'), '')
      .replaceAll(RegExp('_$regexPattern'), '');

  _abbr2TickerCache[abbr] = ticker;
  return ticker;
}

final Map<String, String> _abbr2TickerCache = {};
