import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/model/kdf_auth_metadata_extension.dart';
import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/services/storage/base_storage.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/constants.dart';

class SettingsRepository {
  SettingsRepository({BaseStorage? storage, KomodoDefiSdk? sdk})
      : _storage = storage ?? getStorage(),
        _kdfSdk = sdk ?? GetIt.I<KomodoDefiSdk>();

  final BaseStorage _storage;
  final KomodoDefiSdk _kdfSdk;

  Future<StoredSettings> loadSettings() async {
    final dynamic storedAppPrefs = await _storage.read(storedSettingsKey);
    final stored = StoredSettings.fromJson(storedAppPrefs);
    final hideZeroBalance = await _kdfSdk.getHideZeroBalanceAssets();
    return stored.copyWith(hideZeroBalanceAssets: hideZeroBalance);
  }

  Future<void> updateSettings(StoredSettings settings) async {
    final data = settings.toJson()..remove('hideZeroBalanceAssets');
    await _kdfSdk.setHideZeroBalanceAssets(settings.hideZeroBalanceAssets);
    final String encodedData = jsonEncode(data);
    await _storage.write(storedSettingsKey, encodedData);
  }

  static Future<StoredSettings> loadStoredSettings() async {
    final storage = getStorage();
    final dynamic storedAppPrefs = await storage.read(storedSettingsKey);
    final stored = StoredSettings.fromJson(storedAppPrefs);
    final kdf = GetIt.I<KomodoDefiSdk>();
    final hideZeroBalance = await kdf.getHideZeroBalanceAssets();
    return stored.copyWith(hideZeroBalanceAssets: hideZeroBalance);
  }
}
