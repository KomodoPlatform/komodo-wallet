import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dex/services/storage/base_storage.dart';
import 'package:web_dex/shared/utils/utils.dart';

class AppStorage implements BaseStorage {
  SharedPreferences? _prefs;

  @override
  Future<bool> write(String key, dynamic data) async {
    try {
      await _writeToSharedPrefs(key, data);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<dynamic> read(String key) async {
    final SharedPreferences prefs = await _getPreferences();
    await prefs.reload();
    try {
      final dynamic value = prefs.get(key);
      if (value is String) {
        try {
          return jsonDecode(value);
        } catch (_) {
          return value;
        }
      } else {
        return value;
      }
    } catch (e, s) {
      log(e.toString(), path: 'web_storage => read', trace: s, isError: true);
      return null;
    }
  }

  @override
  Future<bool> delete(String key) async {
    final SharedPreferences prefs = await _getPreferences();
    return prefs.remove(key);
  }

  Future<void> _writeToSharedPrefs(String key, dynamic data) async {
    final SharedPreferences prefs = await _getPreferences();

    switch (data.runtimeType) {
      case bool:
        await prefs.setBool(key, data);
        break;
      case double:
        await prefs.setDouble(key, data);
        break;
      case int:
        await prefs.setInt(key, data);
        break;
      case String:
        await prefs.setString(key, data);
        break;
      default:
        await prefs.setString(key, jsonEncode(data));
    }
  }

  Future<SharedPreferences> _getPreferences() async {
    if (_prefs != null) {
      return Future.value(_prefs);
    }
    _prefs = await SharedPreferences.getInstance();

    return Future.value(_prefs);
  }
}
