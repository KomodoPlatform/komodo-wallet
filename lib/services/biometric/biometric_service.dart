import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Service for managing biometric authentication (Face ID, Touch ID, Fingerprint).
///
/// Provides functionality to check biometric availability, authenticate users,
/// and manage biometric preferences.
class BiometricService {
  BiometricService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? storage,
  }) : _localAuth = localAuth ?? LocalAuthentication(),
       _storage = storage ?? const FlutterSecureStorage();

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _storage;

  static const String _biometricEnabledKey = 'app_biometric_enabled';

  /// Checks if biometric authentication is available on this device.
  Future<bool> isAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Gets the list of available biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticates the user using biometrics.
  ///
  /// Returns true if authentication succeeds, false otherwise.
  /// The [reason] parameter explains why authentication is needed.
  Future<bool> authenticate({required String reason}) async {
    try {
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Checks if biometric authentication is enabled for the app.
  Future<bool> isEnabled() async {
    try {
      final enabled = await _storage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enables or disables biometric authentication for the app.
  Future<void> setEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Gets a user-friendly name for the available biometric type.
  ///
  /// Returns 'Face ID', 'Touch ID', 'Fingerprint', or 'Biometric' depending
  /// on what's available on the device.
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      // iOS calls it Touch ID, Android calls it Fingerprint
      return 'Touch ID';
    } else if (biometrics.contains(BiometricType.strong) ||
        biometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }

    return 'Biometric';
  }

  /// Clears biometric preferences.
  Future<void> clearBiometric() async {
    await _storage.delete(key: _biometricEnabledKey);
  }
}
