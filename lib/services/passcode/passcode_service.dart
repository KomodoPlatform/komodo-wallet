import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing passcode authentication.
///
/// Provides functionality to create, verify, and manage 6-digit passcodes
/// for quick app authentication. Passcodes are hashed before storage for security.
class PasscodeService {
  PasscodeService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _passcodeHashKey = 'app_passcode_hash';
  static const String _passcodeEnabledKey = 'app_passcode_enabled';
  static const String _passcodeSaltKey = 'app_passcode_salt';

  /// Creates and stores a new passcode.
  ///
  /// The passcode is hashed with SHA-512 and a random salt before storage.
  /// Returns true if successful, false otherwise.
  Future<bool> setPasscode(String passcode) async {
    if (passcode.length != 6 || !_isNumeric(passcode)) {
      return false;
    }

    try {
      // Generate a random salt
      final salt = _generateSalt();

      // Hash the passcode with the salt
      final hash = _hashPasscode(passcode, salt);

      // Store both hash and salt
      await _storage.write(key: _passcodeHashKey, value: hash);
      await _storage.write(key: _passcodeSaltKey, value: salt);
      await _storage.write(key: _passcodeEnabledKey, value: 'true');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verifies a passcode attempt.
  ///
  /// Returns true if the passcode matches the stored hash, false otherwise.
  Future<bool> verifyPasscode(String passcode) async {
    if (passcode.length != 6 || !_isNumeric(passcode)) {
      return false;
    }

    try {
      final storedHash = await _storage.read(key: _passcodeHashKey);
      final salt = await _storage.read(key: _passcodeSaltKey);

      if (storedHash == null || salt == null) {
        return false;
      }

      final inputHash = _hashPasscode(passcode, salt);
      return inputHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// Checks if passcode authentication is enabled.
  Future<bool> isPasscodeEnabled() async {
    try {
      final enabled = await _storage.read(key: _passcodeEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enables or disables passcode authentication.
  Future<void> setPasscodeEnabled(bool enabled) async {
    await _storage.write(
      key: _passcodeEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Removes all passcode data.
  ///
  /// This should be called when resetting passcode or disabling it completely.
  Future<void> clearPasscode() async {
    await _storage.delete(key: _passcodeHashKey);
    await _storage.delete(key: _passcodeSaltKey);
    await _storage.delete(key: _passcodeEnabledKey);
  }

  /// Hashes a passcode with a salt using SHA-512.
  String _hashPasscode(String passcode, String salt) {
    final bytes = utf8.encode(passcode + salt);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }

  /// Generates a random salt for passcode hashing.
  String _generateSalt() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode * 31).toString();
    return _hashPasscode(random, timestamp);
  }

  /// Validates that a string contains only numeric characters.
  bool _isNumeric(String str) {
    return RegExp(r'^\d+$').hasMatch(str);
  }
}
