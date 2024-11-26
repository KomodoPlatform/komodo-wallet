import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/model/coin.dart';

final CoinConfigParser coinConfigParser = CoinConfigParser();

class CoinConfigParser {
  List<dynamic>? _globalConfigCache;

  Future<List<dynamic>> getGlobalCoinsJson() async {
    final List<dynamic> globalConfig =
        _globalConfigCache ?? await _readGlobalConfig();
    final List<dynamic> filtered = _removeDelisted(globalConfig);

    return filtered;
  }

  Future<List<dynamic>> _readGlobalConfig() async {
    final String globalConfig =
        await rootBundle.loadString('$coinsAssetsPath/config/coins.json');
    final List<dynamic> globalCoinsJson = jsonDecode(globalConfig);

    _globalConfigCache = globalCoinsJson;
    return globalCoinsJson;
  }

  /// Checks if the specified asset [path] exists.
  /// Returns `true` if the asset exists, otherwise `false`.
  Future<bool> doesAssetExist(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the local coin configs exist.
  /// Returns `true` if the local coin configs exist, otherwise `false`.
  Future<bool> hasLocalConfigs({
    String coinsPath = '$coinsAssetsPath/config/coins.json',
    String coinsConfigPath = '$coinsAssetsPath/config/coins_config.json',
  }) async {
    try {
      final bool coinsFileExists = await doesAssetExist(coinsPath);
      final bool coinsConfigFileExists = await doesAssetExist(coinsConfigPath);
      return coinsFileExists && coinsConfigFileExists;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getUnifiedCoinsJson() async {
    final Map<String, dynamic> json = await _readLocalConfig();
    final Map<String, dynamic> modifiedJson = _modifyLocalJson(json);

    return modifiedJson;
  }

  Map<String, dynamic> _modifyLocalJson(Map<String, dynamic> source) {
    final Map<String, dynamic> modifiedJson = <String, dynamic>{};

    source.forEach((abbr, dynamic coinItem) {
      if (_needSkipCoin(coinItem)) return;

      dynamic electrum = coinItem['electrum'];
      // Web doesn't support SSL and TCP protocols, so we need to remove
      // electrum servers with these protocols.
      if (kIsWeb) {
        removeElectrumsWithoutWss(electrum);
      }

      coinItem['abbr'] = abbr;
      coinItem['priority'] = priorityCoinsAbbrMap[abbr] ?? 0;
      coinItem['active'] = enabledByDefaultCoins.contains(abbr);
      modifiedJson[abbr] = coinItem;
    });

    return modifiedJson;
  }

  /// Remove electrum servers without WSS protocol from [electrums].
  /// If [electrums] is a list, it will be modified in place.
  /// Leaving as in-place modification for performance reasons.
  void removeElectrumsWithoutWss(dynamic electrums) {
    if (electrums is List) {
      for (final e in electrums) {
        if (e['protocol'] == 'WSS') {
          e['ws_url'] = e['url'];
        }
      }

      electrums.removeWhere((dynamic e) => e['ws_url'] == null);
    }
  }

  Future<Map<String, dynamic>> _readLocalConfig() async {
    final String localConfig =
        await rootBundle.loadString('$coinsAssetsPath/config/coins_config.json');
    final Map<String, dynamic> json = jsonDecode(localConfig);

    return json;
  }

  bool _needSkipCoin(Map<String, dynamic> jsonCoin) {
    final dynamic electrum = jsonCoin['electrum'];
    if (excludedAssetList.contains(jsonCoin['coin'])) {
      return true;
    }
    if (getCoinType(jsonCoin['type'], jsonCoin['coin']) == null) {
      return true;
    }

    return electrum is List &&
        electrum.every((dynamic e) =>
            e['ws_url'] == null && !_isProtocolSupported(e['protocol']));
  }

  /// Returns true if [protocol] is supported on the current platform.
  /// On web, only WSS is supported.
  /// On other (native) platforms, only SSL and TCP are supported.
  bool _isProtocolSupported(String? protocol) {
    if (protocol == null) {
      return false;
    }

    String uppercaseProtocol = protocol.toUpperCase();

    if (kIsWeb) {
      return uppercaseProtocol == 'WSS';
    }

    return uppercaseProtocol == 'SSL' || uppercaseProtocol == 'TCP';
  }

  List<dynamic> _removeDelisted(List<dynamic> all) {
    final List<dynamic> filtered = List<dynamic>.from(all);
    filtered.removeWhere(
      (dynamic item) => excludedAssetList.contains(item['coin']),
    );
    return filtered;
  }
}
