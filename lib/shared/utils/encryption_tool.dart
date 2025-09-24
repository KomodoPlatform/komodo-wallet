import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:web_dex/shared/utils/legacy_desktop_decryption_selector.dart';

class EncryptionTool {
  LegacyDesktopDecryption? _legacyDecryption;

  EncryptionTool() {
    try {
      _legacyDecryption = LegacyDesktopDecryption();
    } catch (e) {
      // Legacy decryption not available on this platform
      // Will fall back to standard decryption methods
      _legacyDecryption = null;
    }
  }

  /// Encrypts the provided [data] using AES encryption with the given [password].
  ///
  /// Parameters:
  /// - [password] (String): The password used for encryption key derivation.
  /// - [data] (String): The data to be encrypted.
  ///
  /// Return Value:
  /// - Future<String>: A JSON-encoded string containing the encrypted data and IVs.
  ///
  /// Example Usage:
  /// ```dart
  /// String password = 'securepassword';
  /// String data = 'confidential information';
  ///
  /// String encryptedResult = await encryptData(password, data);
  /// print(encryptedResult); // Output: JSON-encoded string with encrypted data and IVs
  /// ```
  /// unit tests [testEncryptDataTool]
  Future<String> encryptData(String password, String data) async {
    final iv1 = IV.fromLength(16);
    final iv2 = IV.fromLength(16);
    final secretKey = await _pbkdf2Key(password, iv2.bytes);

    final encrypter = Encrypter(AES(secretKey, mode: AESMode.cbc));
    final Encrypted encrypted = encrypter.encrypt(data, iv: iv1);

    final String result = jsonEncode(<String, dynamic>{
      '0': base64.encode(encrypted.bytes),
      '1': base64.encode(iv1.bytes),
      '2': base64.encode(iv2.bytes),
    });

    return result;
  }

  /// Decrypts the provided [encryptedData] using AES decryption with the given [password].
  /// The method attempts to decode the [encryptedData] as a JSON-encoded string
  /// containing encrypted data and initialization vectors (IVs).
  ///
  /// Also supports legacy desktop wallet format encrypted with XChaCha20-Poly1305.
  ///
  /// Parameters:
  /// - [password] (String): The password used for decryption key derivation.
  /// - [encryptedData] (String): The JSON-encoded string containing encrypted data and IVs,
  ///   or legacy desktop wallet encrypted data.
  ///
  /// Return Value:
  /// - Future<String?>: The decrypted data, or `null` if decryption fails.
  ///
  /// Example Usage:
  /// ```dart
  /// String password = 'securepassword';
  /// String encryptedData = '{"0":"...", "1":"...", "2":"..."}';
  ///
  /// String? decryptedResult = await decryptData(password, encryptedData);
  /// print(decryptedResult); // Output: Decrypted data or null if decryption fails
  /// ```
  /// unit tests [testEncryptDataTool]
  Future<String?> decryptData(String password, String encryptedData) async {
    try {
      final Map<String, dynamic> json = jsonDecode(encryptedData);
      final Uint8List data = Uint8List.fromList(base64.decode(json['0']));
      final IV iv1 = IV.fromBase64(json['1']);
      final IV iv2 = IV.fromBase64(json['2']);

      final secretKey = await _pbkdf2Key(password, iv2.bytes);

      final encrypter = Encrypter(AES(secretKey, mode: AESMode.cbc));
      final String decrypted = encrypter.decrypt(Encrypted(data), iv: iv1);

      return decrypted;
    } catch (_) {
      // Try legacy desktop format if standard decryption fails
      return _decryptLegacyData(password, encryptedData);
    }
  }

  /// Attempts to decrypt legacy desktop wallet data
  String? _decryptLegacyData(String password, String encryptedData) {
    // First try the old AES legacy format
    final legacyResult = _decryptLegacy(password, encryptedData);
    if (legacyResult != null) {
      return legacyResult;
    }

    // Try legacy desktop XChaCha20-Poly1305 format
    try {
      final dataBytes = _tryDecodeAsBytes(encryptedData);
      if (dataBytes != null &&
          _legacyDecryption?.isLegacyFormat(dataBytes) == true) {
        return _legacyDecryption!.decryptLegacySeed(password, dataBytes);
      }
    } catch (e) {
      // Legacy decryption not available or failed
    }

    return null;
  }

  /// Tries to decode string data as bytes for legacy format detection
  Uint8List? _tryDecodeAsBytes(String data) {
    try {
      // Try base64 decode first
      return base64.decode(data);
    } catch (e) {
      try {
        // Try treating as hex string
        if (data.length % 2 == 0) {
          final bytes = <int>[];
          for (int i = 0; i < data.length; i += 2) {
            final hexByte = data.substring(i, i + 2);
            bytes.add(int.parse(hexByte, radix: 16));
          }
          return Uint8List.fromList(bytes);
        }
      } catch (e) {
        // Try UTF-8 encoding as last resort
        try {
          return Uint8List.fromList(utf8.encode(data));
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  /// Supports decryption from file bytes for legacy desktop wallets
  Future<String?> decryptDataFromBytes(
    String password,
    Uint8List encryptedBytes,
  ) async {
    try {
      // Check if it's legacy desktop format
      if (isLegacyDesktopFormat(encryptedBytes)) {
        return _legacyDecryption!.decryptLegacySeed(password, encryptedBytes);
      }

      // Try to decode as string and use standard decryption
      final dataString = utf8.decode(encryptedBytes, allowMalformed: true);
      return await decryptData(password, dataString);
    } catch (e) {
      return null;
    }
  }

  /// Checks if the provided data is in legacy desktop format
  bool isLegacyDesktopFormat(Uint8List fileData) {
    try {
      return _legacyDecryption?.isLegacyFormat(fileData) ?? false;
    } catch (e) {
      // Legacy decryption not available
      return false;
    }
  }

  String? _decryptLegacy(String password, String encryptedData) {
    try {
      final String length32Key = md5.convert(utf8.encode(password)).toString();
      final key = Key.fromUtf8(length32Key);
      final IV iv = IV.allZerosOfLength(16);

      final Encrypter encrypter = Encrypter(AES(key));
      final Encrypted encrypted = Encrypted.fromBase64(encryptedData);
      final decryptedData = encrypter.decrypt(encrypted, iv: iv);

      return decryptedData;
    } catch (_) {
      return null;
    }
  }

  Future<Key> _pbkdf2Key(String password, Uint8List salt) async {
    return Key.fromUtf8(password).stretch(16, iterationCount: 1000, salt: salt);
  }
}
