import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Legacy Desktop Wallet Decryption Tool (Native - FFI)
///
/// This class handles decryption of legacy desktop wallet files that were encrypted
/// using XChaCha20-Poly1305 with libsodium, as used in the original AtomicDEX desktop app.
///
/// The legacy encryption format uses:
/// - crypto_secretstream_xchacha20poly1305 for encryption
/// - crypto_pwhash with zeroed salt for key derivation (not optimal)
/// - Header + chunked encrypted data format
class LegacyDesktopDecryption {
  static const int _saltLen = 32; // crypto_pwhash_SALTBYTES
  static const int _chunkSize = 4096;
  static const int _abytes = 17; // crypto_secretstream_xchacha20poly1305_ABYTES
  static const int _buffLen = _chunkSize + _abytes;
  static const int _headerSize =
      24; // crypto_secretstream_xchacha20poly1305_HEADERBYTES
  static const int _keySize =
      32; // crypto_secretstream_xchacha20poly1305_KEYBYTES

  // Libsodium constants
  static const int _cryptoPwhashOpsLimitInteractive =
      2; // sodium OPslimit interactive
  static const int _cryptoPwhashMemLimitInteractive =
      67108864; // sodium MEMlimit interactive
  static const int _cryptoPwhashAlgDefault = 2;
  static const int _cryptoSecretstreamXchacha20poly1305TagFinal = 3;

  late final DynamicLibrary _sodium;

  LegacyDesktopDecryption() {
    _loadSodiumLibrary();
  }

  void _loadSodiumLibrary() {
    try {
      if (Platform.isLinux || Platform.isAndroid) {
        _sodium = _tryOpenAny([
          'libsodium.so',
          'libsodium.so.23',
          'libsodium.so.26',
        ]);
      } else if (Platform.isMacOS || Platform.isIOS) {
        _sodium = _tryOpenAny([
          'libsodium.dylib',
          '/usr/local/lib/libsodium.dylib',
          '/opt/homebrew/lib/libsodium.dylib',
          '/usr/local/opt/libsodium/lib/libsodium.dylib',
          '/opt/homebrew/opt/libsodium/lib/libsodium.dylib',
          '${Directory.current.path}/Frameworks/libsodium.framework/libsodium',
        ]);
      } else if (Platform.isWindows) {
        _sodium = _tryOpenAny(['sodium.dll', 'libsodium.dll']);
      } else {
        throw UnsupportedError('Platform not supported for legacy decryption');
      }
    } catch (e) {
      throw Exception(
        'Failed to load libsodium library. Please ensure libsodium is installed: $e',
      );
    }
  }

  DynamicLibrary _tryOpenAny(List<String> candidates) {
    for (final name in candidates) {
      try {
        return DynamicLibrary.open(name);
      } catch (_) {}
    }
    throw Exception('Unable to open libsodium from candidates: $candidates');
  }

  /// Derives a password-based key using libsodium's crypto_pwhash
  /// Note: The legacy implementation used a zeroed salt which is not secure
  Uint8List _derivePasswordKey(String password) {
    final passwordPtr = password.toNativeUtf8();
    final keyPtr = malloc<Uint8>(_keySize);
    final saltPtr = malloc<Uint8>(_saltLen);

    try {
      // Zero out the salt (matching legacy behavior)
      for (int i = 0; i < _saltLen; i++) {
        saltPtr[i] = 0;
      }

      final cryptoPwhash = _sodium
          .lookupFunction<
            Int32 Function(
              Pointer<Uint8>,
              Uint64,
              Pointer<Utf8>,
              Uint64,
              Pointer<Uint8>,
              Uint64,
              Uint64,
              Int32,
            ),
            int Function(
              Pointer<Uint8>,
              int,
              Pointer<Utf8>,
              int,
              Pointer<Uint8>,
              int,
              int,
              int,
            )
          >('crypto_pwhash');

      final result = cryptoPwhash(
        keyPtr,
        _keySize,
        passwordPtr,
        password.length,
        saltPtr,
        _cryptoPwhashOpsLimitInteractive,
        _cryptoPwhashMemLimitInteractive,
        _cryptoPwhashAlgDefault,
      );

      if (result != 0) {
        throw Exception('Failed to derive password key');
      }

      return Uint8List.fromList(keyPtr.asTypedList(_keySize));
    } finally {
      malloc.free(passwordPtr);
      malloc.free(keyPtr);
      malloc.free(saltPtr);
    }
  }

  /// Decrypts legacy desktop wallet file data
  ///
  /// [password] - The password used to encrypt the wallet
  /// [encryptedFileData] - The raw bytes from the encrypted wallet file
  ///
  /// Returns the decrypted mnemonic/seed phrase or null if decryption fails
  String? decryptLegacySeed(String password, Uint8List encryptedFileData) {
    try {
      if (encryptedFileData.length < _headerSize) {
        return null;
      }

      final key = _derivePasswordKey(password);

      // Extract header
      final header = encryptedFileData.sublist(0, _headerSize);
      final encryptedData = encryptedFileData.sublist(_headerSize);

      // Initialize decryption state
      final statePtr = malloc<Uint8>(
        52,
      ); // crypto_secretstream_xchacha20poly1305_state size
      final keyPtr = malloc<Uint8>(_keySize);
      final headerPtr = malloc<Uint8>(_headerSize);

      try {
        // Copy key and header to native memory
        for (int i = 0; i < _keySize; i++) {
          keyPtr[i] = key[i];
        }
        for (int i = 0; i < _headerSize; i++) {
          headerPtr[i] = header[i];
        }

        final initPull = _sodium
            .lookupFunction<
              Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>),
              int Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>)
            >('crypto_secretstream_xchacha20poly1305_init_pull');

        if (initPull(statePtr, headerPtr, keyPtr) != 0) {
          return null; // Wrong password or corrupted header
        }

        // Decrypt the data in chunks
        final decryptedData = <int>[];
        int offset = 0;

        final pull = _sodium
            .lookupFunction<
              Int32 Function(
                Pointer<Uint8>,
                Pointer<Uint8>,
                Pointer<Uint64>,
                Pointer<Uint8>,
                Pointer<Uint8>,
                Uint64,
                Pointer<Uint8>,
                Uint64,
              ),
              int Function(
                Pointer<Uint8>,
                Pointer<Uint8>,
                Pointer<Uint64>,
                Pointer<Uint8>,
                Pointer<Uint8>,
                int,
                Pointer<Uint8>,
                int,
              )
            >('crypto_secretstream_xchacha20poly1305_pull');

        final bufOutPtr = malloc<Uint8>(_chunkSize);
        final outLenPtr = malloc<Uint64>();
        final tagPtr = malloc<Uint8>();

        try {
          while (offset < encryptedData.length) {
            final chunkSize = (offset + _buffLen <= encryptedData.length)
                ? _buffLen
                : encryptedData.length - offset;

            final bufInPtr = malloc<Uint8>(chunkSize);
            try {
              // Copy chunk to native memory
              for (int i = 0; i < chunkSize; i++) {
                bufInPtr[i] = encryptedData[offset + i];
              }

              final result = pull(
                statePtr,
                bufOutPtr,
                outLenPtr,
                tagPtr,
                bufInPtr,
                chunkSize,
                nullptr,
                0,
              );

              if (result != 0) {
                return null; // Decryption failed
              }

              final outLen = outLenPtr.value;
              final tag = tagPtr.value;

              // Add decrypted chunk to result
              for (int i = 0; i < outLen; i++) {
                decryptedData.add(bufOutPtr[i]);
              }

              // Check if this is the final chunk
              if (tag == _cryptoSecretstreamXchacha20poly1305TagFinal) {
                break;
              }

              offset += chunkSize;
            } finally {
              malloc.free(bufInPtr);
            }
          }
        } finally {
          malloc.free(bufOutPtr);
          malloc.free(outLenPtr);
          malloc.free(tagPtr);
        }

        // Convert decrypted bytes to string
        return utf8.decode(decryptedData);
      } finally {
        malloc.free(statePtr);
        malloc.free(keyPtr);
        malloc.free(headerPtr);
      }
    } catch (e) {
      return null;
    }
  }

  /// Attempts to detect if file data is in legacy format
  /// Legacy files start with a specific header structure
  bool isLegacyFormat(Uint8List fileData) {
    // Legacy files should have at least the header size
    if (fileData.length < _headerSize) {
      return false;
    }

    try {
      // Check if it's not JSON (current format starts with '{')
      // and not base64 (current legacy fallback format)
      if (fileData[0] == 123) return false; // '{'

      final asString = utf8.decode(fileData, allowMalformed: true);
      if (asString.startsWith('{') || _isBase64(asString)) {
        return false;
      }

      return true;
    } catch (e) {
      // If it can't be decoded as UTF-8, it's likely binary (legacy)
      return true;
    }
  }

  bool _isBase64(String str) {
    try {
      base64.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}



