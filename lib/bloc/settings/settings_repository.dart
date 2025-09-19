import 'dart:convert';

import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/services/storage/base_storage.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/constants.dart';

class SettingsRepository {
  SettingsRepository({BaseStorage? storage})
      : _storage = storage ?? getStorage();

  final BaseStorage _storage;

  Future<StoredSettings> loadSettings() async {
    final dynamic storedAppPrefs = await _storage.read(storedSettingsKey);

    return StoredSettings.fromJson(storedAppPrefs);
  }

  Future<void> updateSettings(StoredSettings settings) async {
    final String encodedData = jsonEncode(settings.toJson());
    await _storage.write(storedSettingsKey, encodedData);
  }

  static Future<StoredSettings> loadStoredSettings() async {
    final storage = getStorage();
    final dynamic storedAppPrefs = await storage.read(storedSettingsKey);

    return StoredSettings.fromJson(storedAppPrefs);
  }
}
