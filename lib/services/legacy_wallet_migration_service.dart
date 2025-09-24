import 'dart:convert';
import 'dart:typed_data';

import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/model/legacy_wallet_data.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';
import 'package:web_dex/shared/utils/utils.dart';

/// Service for migrating legacy desktop wallet data to the new cross-platform format
class LegacyWalletMigrationService {
  final EncryptionTool _encryptionTool = EncryptionTool();

  /// Migrates a legacy desktop wallet file to the new format
  ///
  /// [fileData] - Raw bytes from the legacy wallet file
  /// [password] - Password used to decrypt the legacy wallet
  /// [newWalletName] - Name for the new wallet (optional, will use legacy name if not provided)
  ///
  /// Returns a [LegacyWalletData] object with all migrated data, or null if migration fails
  Future<LegacyWalletData?> migrateLegacyWallet({
    required Uint8List fileData,
    required String password,
    String? newWalletName,
  }) async {
    try {
      // First, try to decrypt as legacy desktop format
      final decryptedMnemonic = await _encryptionTool.decryptDataFromBytes(
        password,
        fileData,
      );
      if (decryptedMnemonic == null) {
        return null; // Failed to decrypt
      }

      // Try to parse as JSON in case it contains more than just the mnemonic
      try {
        final jsonData = jsonDecode(decryptedMnemonic);
        if (jsonData is Map<String, dynamic>) {
          // Full legacy wallet data
          return LegacyWalletData.fromJson(jsonData);
        }
      } catch (e) {
        // Not JSON, likely just a mnemonic string
      }

      // If we only have a mnemonic, create minimal legacy data
      final walletName = newWalletName ?? 'Migrated Legacy Wallet';
      return LegacyWalletData.seedOnly(
        walletName: walletName,
        mnemonic: decryptedMnemonic.trim(),
      );
    } catch (e) {
      log(
        'Failed to migrate legacy wallet: $e',
        path: 'LegacyWalletMigrationService.migrateLegacyWallet',
        isError: true,
      );
      return null;
    }
  }

  /// Converts legacy wallet data to new WalletConfig format
  ///
  /// [legacyData] - The migrated legacy wallet data
  /// [walletType] - Type of wallet to create (HD or iguana)
  /// [newPassword] - Password for encrypting the new wallet
  ///
  /// Returns a [WalletConfig] that can be used to create a new wallet
  Future<WalletConfig> convertToWalletConfig({
    required LegacyWalletData legacyData,
    required WalletType walletType,
    required String newPassword,
  }) async {
    // Encrypt the mnemonic with the new password
    final encryptedSeed = await _encryptionTool.encryptData(
      newPassword,
      legacyData.mnemonic,
    );

    return WalletConfig(
      type: walletType,
      seedPhrase: encryptedSeed,
      activatedCoins: enabledByDefaultCoins,
      hasBackup: true,
      isLegacyWallet: false, // It's been migrated to new format
    );
  }

  /// Attempts to detect if file data is in legacy desktop format
  bool isLegacyDesktopFormat(Uint8List fileData) {
    try {
      // Try to decode as current format first
      final asString = utf8.decode(fileData, allowMalformed: true);

      // Current format starts with JSON
      if (asString.startsWith('{')) {
        return false;
      }

      // Current legacy format is base64
      try {
        final decoded = jsonDecode(asString);
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('0') &&
            decoded.containsKey('1') &&
            decoded.containsKey('2')) {
          return false; // Current encryption format
        }
      } catch (e) {
        // Not current format, continue checking
      }

      // Use legacy decryption tool to detect format
      final toolResult = _encryptionTool.isLegacyDesktopFormat(fileData);
      if (toolResult) return true;

      // Fallback to heuristic detection that does not require libsodium
      return _heuristicIsLegacyFormat(fileData);
    } catch (e) {
      // If we can't analyze the format, assume it might be legacy
      return true;
    }
  }

  bool _heuristicIsLegacyFormat(Uint8List fileData) {
    // Legacy files should have at least the header size used by secretstream (24 bytes)
    if (fileData.length < 24) {
      return false;
    }

    try {
      // If it starts with JSON, it's new format
      if (fileData[0] == 123) {
        // '{'
        return false;
      }

      final asString = utf8.decode(fileData, allowMalformed: true);
      if (asString.startsWith('{')) {
        return false;
      }

      // If it's valid base64 or looks like our JSON-wrapped AES payload, it's not legacy
      try {
        final decoded = jsonDecode(asString);
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('0') &&
            decoded.containsKey('1') &&
            decoded.containsKey('2')) {
          return false;
        }
      } catch (_) {
        // ignore
      }

      // Try base64 decode; if it decodes cleanly it's likely not the binary legacy header
      try {
        base64.decode(asString);
        return false;
      } catch (_) {
        // not base64 -> likely binary legacy format
      }

      return true;
    } catch (_) {
      // If UTF-8 decoding fails badly, it's likely binary legacy
      return true;
    }
  }

  /// Validates that a mnemonic is valid BIP39
  bool isValidMnemonic(String mnemonic) {
    // This would typically use a BIP39 library
    // For now, do basic validation
    final words = mnemonic.trim().split(' ');
    return words.length >= 12 && words.length <= 24 && words.length % 3 == 0;
  }

  /// Exports legacy wallet data to a JSON format for backup
  String exportLegacyDataAsJson(LegacyWalletData legacyData) {
    return jsonEncode(legacyData.toJson());
  }

  /// Imports additional legacy data (address book, swap history, etc.) to supplement a wallet
  /// This can be used when a user has separate files for different data types
  Future<LegacyWalletData?> importAdditionalLegacyData({
    required Uint8List fileData,
    required String password,
    required LegacyWalletData existingData,
  }) async {
    try {
      final decryptedData = await _encryptionTool.decryptDataFromBytes(
        password,
        fileData,
      );
      if (decryptedData == null) {
        return null;
      }

      final jsonData = jsonDecode(decryptedData);
      if (jsonData is! Map<String, dynamic>) {
        return null;
      }

      // Merge the additional data with existing
      final additionalData = LegacyWalletData.fromJson(jsonData);

      return LegacyWalletData(
        walletName: existingData.walletName,
        mnemonic: existingData.mnemonic,
        addressBook: [
          ...existingData.addressBook,
          ...additionalData.addressBook,
        ],
        swapHistory: [
          ...existingData.swapHistory,
          ...additionalData.swapHistory,
        ],
        makerOrders: [
          ...existingData.makerOrders,
          ...additionalData.makerOrders,
        ],
        makerbotConfigs: [
          ...existingData.makerbotConfigs,
          ...additionalData.makerbotConfigs,
        ],
        settings: {...existingData.settings, ...additionalData.settings},
        exportedAt: DateTime.now(),
      );
    } catch (e) {
      log(
        'Failed to import additional legacy data: $e',
        path: 'LegacyWalletMigrationService.importAdditionalLegacyData',
        isError: true,
      );
      return null;
    }
  }

  /// Validates legacy wallet data integrity
  bool validateLegacyData(LegacyWalletData data) {
    // Check mnemonic is valid
    if (!isValidMnemonic(data.mnemonic)) {
      return false;
    }

    // Check wallet name is not empty
    if (data.walletName.trim().isEmpty) {
      return false;
    }

    // Validate address book entries
    for (final entry in data.addressBook) {
      if (entry.address.trim().isEmpty || entry.name.trim().isEmpty) {
        return false;
      }
    }

    // Additional validation could be added here
    return true;
  }
}
