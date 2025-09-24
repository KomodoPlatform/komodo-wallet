import 'dart:convert';
import 'dart:typed_data';

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Legacy Desktop Wallet Decryption Tool (Web)
///
/// Uses a JS helper (web/services/legacy_decryption/legacy_decrypt.js)
/// backed by libsodium-wrappers to decrypt XChaCha20-Poly1305 secretstream
/// data produced by AtomicDEX desktop.
class LegacyDesktopDecryption {
  String? decryptLegacySeed(String password, Uint8List encryptedFileData) {
    try {
      final helper = globalContext.getProperty('legacyDecrypt'.toJS);
      if (helper == null) return null;

      final toB64 = base64.encode(encryptedFileData);
      final jsResult = (helper as JSObject).callMethod(
        'decryptLegacySeedBase64'.toJS,
        <JSAny?>[password.toJS, toB64.toJS].toJS,
      );
      final result = jsResult.dartify();
      if (result is String) {
        return result;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool isLegacyFormat(Uint8List fileData) {
    try {
      final helper = globalContext.getProperty('legacyDecrypt'.toJS);
      if (helper == null) return _heuristicIsLegacy(fileData);

      final toB64 = base64.encode(fileData);
      final jsResult = (helper as JSObject).callMethod(
        'isLegacyFormatBase64'.toJS,
        <JSAny?>[toB64.toJS].toJS,
      );
      final result = jsResult.dartify();
      if (result is bool) return result;
      return _heuristicIsLegacy(fileData);
    } catch (_) {
      return _heuristicIsLegacy(fileData);
    }
  }

  bool _heuristicIsLegacy(Uint8List fileData) {
    if (fileData.length < 24) return false;
    try {
      if (fileData[0] == 123) return false; // '{'
      final asString = utf8.decode(fileData, allowMalformed: true);
      if (asString.startsWith('{')) return false;
      // Likely not base64 if decoding throws, which suggests binary
      try {
        base64.decode(asString);
        return false;
      } catch (_) {
        // not base64 -> likely legacy binary
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}
