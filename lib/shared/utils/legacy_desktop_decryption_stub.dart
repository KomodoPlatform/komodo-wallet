import 'dart:typed_data';

/// Stub fallback when platform-specific legacy decryption is not available
class LegacyDesktopDecryption {
  String? decryptLegacySeed(String password, Uint8List encryptedFileData) {
    return null;
  }

  Future<String?> decryptLegacySeedAsync(
    String password,
    Uint8List encryptedFileData,
  ) async {
    return null;
  }

  bool isLegacyFormat(Uint8List fileData) {
    return false;
  }
}
