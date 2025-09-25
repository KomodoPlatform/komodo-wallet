import 'dart:convert';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_import_by_file.dart';

enum WalletFileImportError { incorrectPassword, invalidFile, invalidSeed }

class WalletFileImportOutcome {
  const WalletFileImportOutcome._({this.walletConfig, this.error});

  factory WalletFileImportOutcome.success(WalletConfig walletConfig) =>
      WalletFileImportOutcome._(walletConfig: walletConfig);

  factory WalletFileImportOutcome.failure(WalletFileImportError error) =>
      WalletFileImportOutcome._(error: error);

  final WalletConfig? walletConfig;
  final WalletFileImportError? error;

  bool get isSuccess => walletConfig != null;
}

class WalletFileImportService {
  WalletFileImportService(this._sdk, {EncryptionTool? encryptionTool})
    : _encryptionTool = encryptionTool ?? EncryptionTool();

  final KomodoDefiSdk _sdk;
  final EncryptionTool _encryptionTool;

  Future<WalletFileImportOutcome> parse({
    required WalletFileData fileData,
    required String password,
    required bool isHdMode,
    required bool allowCustomSeed,
  }) async {
    final WalletFileImportOutcome? textResult = await _tryParseJsonExport(
      fileData: fileData,
      password: password,
      isHdMode: isHdMode,
      allowCustomSeed: allowCustomSeed,
    );
    if (textResult != null) {
      return textResult;
    }

    if (fileData.hasBytes) {
      final WalletFileImportOutcome legacyResult = await _tryParseLegacySeed(
        fileData: fileData,
        password: password,
        isHdMode: isHdMode,
        allowCustomSeed: allowCustomSeed,
      );
      if (legacyResult.isSuccess ||
          legacyResult.error == WalletFileImportError.invalidSeed) {
        return legacyResult;
      }
      return WalletFileImportOutcome.failure(
        WalletFileImportError.incorrectPassword,
      );
    }

    return WalletFileImportOutcome.failure(WalletFileImportError.invalidFile);
  }

  Future<WalletFileImportOutcome?> _tryParseJsonExport({
    required WalletFileData fileData,
    required String password,
    required bool isHdMode,
    required bool allowCustomSeed,
  }) async {
    if (!fileData.hasText) {
      return null;
    }

    final String? decryptedPayload = await _encryptionTool.decryptData(
      password,
      fileData.text!,
    );
    if (decryptedPayload == null) {
      return null;
    }

    try {
      final walletJson = json.decode(decryptedPayload);
      if (walletJson is! Map<String, dynamic>) {
        return WalletFileImportOutcome.failure(
          WalletFileImportError.invalidFile,
        );
      }
      final WalletConfig walletConfig = WalletConfig.fromJson(walletJson);
      final String? decryptedSeed = await _encryptionTool.decryptData(
        password,
        walletConfig.seedPhrase,
      );
      if (decryptedSeed == null) {
        return WalletFileImportOutcome.failure(
          WalletFileImportError.incorrectPassword,
        );
      }

      return _buildValidatedOutcome(
        walletConfig: walletConfig,
        decryptedSeed: decryptedSeed,
        isHdMode: isHdMode,
        allowCustomSeed: allowCustomSeed,
      );
    } catch (_) {
      return WalletFileImportOutcome.failure(WalletFileImportError.invalidFile);
    }
  }

  Future<WalletFileImportOutcome> _tryParseLegacySeed({
    required WalletFileData fileData,
    required String password,
    required bool isHdMode,
    required bool allowCustomSeed,
  }) async {
    final seed = await _encryptionTool.decryptLegacyDesktopSeed(
      password: password,
      encryptedBytes: fileData.bytes!,
    );

    if (seed == null) {
      return WalletFileImportOutcome.failure(
        WalletFileImportError.incorrectPassword,
      );
    }

    final WalletConfig walletConfig = WalletConfig(
      seedPhrase: seed,
      activatedCoins: List<String>.from(enabledByDefaultCoins),
      hasBackup: true,
      type: WalletType.iguana,
    );

    return _buildValidatedOutcome(
      walletConfig: walletConfig,
      decryptedSeed: seed,
      isHdMode: isHdMode,
      allowCustomSeed: allowCustomSeed,
    );
  }

  WalletFileImportOutcome _buildValidatedOutcome({
    required WalletConfig walletConfig,
    required String decryptedSeed,
    required bool isHdMode,
    required bool allowCustomSeed,
  }) {
    final List<String> activatedCoins = walletConfig.activatedCoins.isEmpty
        ? List<String>.from(enabledByDefaultCoins)
        : List<String>.from(walletConfig.activatedCoins);

    walletConfig
      ..type = isHdMode ? WalletType.hdwallet : WalletType.iguana
      ..seedPhrase = decryptedSeed
      ..activatedCoins = activatedCoins;

    if ((isHdMode || !allowCustomSeed) &&
        !_sdk.mnemonicValidator.validateBip39(decryptedSeed)) {
      return WalletFileImportOutcome.failure(WalletFileImportError.invalidSeed);
    }

    return WalletFileImportOutcome.success(walletConfig);
  }
}
