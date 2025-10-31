import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/services/storage/base_storage.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/constants.dart';

class SettingsRepository {
  SettingsRepository({BaseStorage? storage})
    : _storage = storage ?? getStorage();

  final BaseStorage _storage;
  static final _log = Logger('SettingsRepository');

  Future<StoredSettings> loadSettings() async {
    return loadStoredSettings();
  }

  Future<void> updateSettings(StoredSettings settings) async {
    // Write the new versioned key for current app reads
    final String v2Data = jsonEncode(settings.toJson());
    await _storage.write(storedSettingsKeyV2, v2Data);

    // Also write a backward-compatible legacy shape so older app versions
    // can continue to read their expected key without crashing.
    final String legacyData = jsonEncode(settings.toLegacyJson());
    await _storage.write(storedSettingsKey, legacyData);
  }

  static Future<StoredSettings> loadStoredSettings() async {
    final storage = getStorage();
    try {
      // Prefer V2 settings if present
      final dynamic v2 = await storage.read(storedSettingsKeyV2);
      if (v2 is Map<String, dynamic>) {
        return StoredSettings.fromJson(v2);
      }

      // Fallback to legacy key
      final dynamic legacy = await storage.read(storedSettingsKey);
      return StoredSettings.fromJson(
        legacy is Map<String, dynamic> ? legacy : null,
      );
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to load stored settings, returning initial settings',
        e,
        stackTrace,
      );
      return StoredSettings.initial();
    }
  }
}
