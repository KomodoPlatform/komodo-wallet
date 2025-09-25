import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:sodium/sodium.dart' show StringX;
import 'package:sodium_libs/sodium_libs_sumo.dart';

class EncryptionTool {
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
  /// Parameters:
  /// - [password] (String): The password used for decryption key derivation.
  /// - [encryptedData] (String): The JSON-encoded string containing encrypted data and IVs.
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
      return _decryptLegacy(password, encryptedData);
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

  Future<String?> decryptLegacyDesktopSeed({
    required String password,
    required Uint8List encryptedBytes,
  }) async {
    if (encryptedBytes.isEmpty) return null;

    try {
      final SodiumSumo sodium = await SodiumSumoInit.init();
      final salt = Uint8List(sodium.crypto.pwhash.saltBytes);
      final key = sodium.crypto.pwhash(
        outLen: sodium.crypto.secretStream.keyBytes,
        password: password.toCharArray(),
        salt: salt,
        opsLimit: sodium.crypto.pwhash.opsLimitInteractive,
        memLimit: sodium.crypto.pwhash.memLimitInteractive,
      );

      try {
        final BytesBuilder plaintextBuilder = BytesBuilder();
        await for (final chunk in sodium.crypto.secretStream.pullChunked(
          cipherStream: Stream<List<int>>.value(encryptedBytes),
          key: key,
          chunkSize: _legacyDesktopChunkSize,
        )) {
          if (chunk.isNotEmpty) {
            plaintextBuilder.add(chunk);
          }
        }

        final Uint8List plaintext = plaintextBuilder.toBytes();
        if (plaintext.isEmpty) {
          return null;
        }
        return utf8.decode(plaintext).trim();
      } catch (_) {
        return null;
      } finally {
        key.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  Future<Key> _pbkdf2Key(String password, Uint8List salt) async {
    return Key.fromUtf8(password).stretch(16, iterationCount: 1000, salt: salt);
  }

  static const int _legacyDesktopChunkSize = 4096;
}
