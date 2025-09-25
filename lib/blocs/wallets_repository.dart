import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/services/storage/base_storage.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';
import 'package:web_dex/shared/utils/utils.dart';

class WalletsRepository {
  WalletsRepository(
    this._kdfSdk,
    this._mm2Api,
    this._legacyWalletStorage, {
    EncryptionTool? encryptionTool,
    FileLoader? fileLoader,
  }) : _encryptionTool = encryptionTool ?? EncryptionTool(),
       _fileLoader = fileLoader ?? FileLoader.fromPlatform();

  final KomodoDefiSdk _kdfSdk;
  final Mm2Api _mm2Api;
  final BaseStorage _legacyWalletStorage;
  final EncryptionTool _encryptionTool;
  final FileLoader _fileLoader;

  List<Wallet>? _cachedWallets;
  List<Wallet>? _cachedLegacyWallets;
  List<Wallet>? get wallets => _cachedWallets;
  bool get isCacheLoaded =>
      _cachedWallets != null && _cachedLegacyWallets != null;

  Future<List<Wallet>> getWallets() async {
    final legacyWallets = await _getLegacyWallets();
    final sdkWallets = await _kdfSdk.wallets;

    // TODO: move wallet filtering logic to the SDK
    _cachedWallets = sdkWallets
        .where(
          (wallet) =>
              wallet.config.type != WalletType.trezor &&
              !wallet.name.toLowerCase().startsWith(trezorWalletNamePrefix),
        )
        .toList();
    _cachedLegacyWallets = legacyWallets;
    return [..._cachedWallets!, ...legacyWallets];
  }

  Future<List<Wallet>> _getLegacyWallets() async {
    final rawLegacyWallets =
        (await _legacyWalletStorage.read(allWalletsStorageKey) as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    return rawLegacyWallets.map((Map<String, dynamic> w) {
      final wallet = Wallet.fromJson(w);
      return wallet.copyWith(
        config: wallet.config.copyWith(
          // Wallet type for legacy wallets is iguana, to avoid confusion with
          // missing/empty balances. Sign into iguana for legacy wallets by
          // default, but allow for them to be signed into hdwallet if desired.
          type: WalletType.iguana,
          isLegacyWallet: true,
        ),
      );
    }).toList();
  }

  Future<void> deleteWallet(Wallet wallet, {required String password}) async {
    log(
      'Deleting a wallet ${wallet.id}',
      path: 'wallet_bloc => deleteWallet',
    ).ignore();

    if (wallet.isLegacyWallet) {
      final wallets = await _getLegacyWallets();
      wallets.removeWhere((w) => w.id == wallet.id);
      await _legacyWalletStorage.write(allWalletsStorageKey, wallets);
      return;
    }

    try {
      await _kdfSdk.auth.deleteWallet(
        walletName: wallet.name,
        password: password,
      );
      _cachedWallets?.removeWhere((w) => w.name == wallet.name);
      return;
    } catch (e) {
      log(
        'Failed to delete wallet: $e',
        path: 'wallet_bloc => deleteWallet',
        isError: true,
      ).ignore();
      rethrow;
    }
  }

  String? validateWalletName(String name) {
    // Disallow special characters except letters, digits, space, underscore and hyphen
    if (RegExp(r'[^\p{L}\p{M}\p{N}\s\-_]', unicode: true).hasMatch(name)) {
      return LocaleKeys.invalidWalletNameError.tr();
    }

    final trimmedName = name.trim();

    // Reject leading/trailing spaces explicitly to avoid confusion/duplicates
    if (trimmedName != name) {
      return LocaleKeys.walletCreationNameLengthError.tr();
    }

    // Check empty and length limits on trimmed input
    if (trimmedName.isEmpty || trimmedName.length > 40) {
      return LocaleKeys.walletCreationNameLengthError.tr();
    }

    return null;
  }

  /// Async uniqueness check: verifies that no existing wallet (SDK or legacy)
  /// has the same trimmed name. Returns a localized error string if taken,
  /// or null if available or if wallets can't be loaded.
  Future<String?> validateWalletNameUniqueness(String name) async {
    final String trimmedName = name.trim();
    try {
      final List<Wallet> allWallets = await getWallets();
      final bool taken =
          allWallets.firstWhereOrNull((w) => w.name.trim() == trimmedName) !=
          null;
      if (taken) {
        return LocaleKeys.walletCreationExistNameError.tr();
      }
    } catch (_) {
      // Non-blocking on failure to fetch wallets; treat as no conflict found.
    }
    return null;
  }

  Future<void> resetSpecificWallet(Wallet wallet) async {
    final coinsToDeactivate = wallet.config.activatedCoins.where(
      (coin) => !enabledByDefaultCoins.contains(coin),
    );
    for (final coin in coinsToDeactivate) {
      await _mm2Api.disableCoin(coin);
    }
  }

  @Deprecated('Use the KomodoDefiSdk.auth.getMnemonicEncrypted method instead.')
  Future<void> downloadEncryptedWallet(Wallet wallet, String password) async {
    try {
      if (wallet.config.seedPhrase.isEmpty) {
        final mnemonic = await _kdfSdk.auth.getMnemonicPlainText(password);
        wallet.config.seedPhrase = await _encryptionTool.encryptData(
          password,
          mnemonic.plaintextMnemonic ?? '',
        );
      }
      final String data = jsonEncode(wallet.config);
      final String encryptedData = await _encryptionTool.encryptData(
        password,
        data,
      );
      final String sanitizedFileName = _sanitizeFileName(wallet.name);
      await _fileLoader.save(
        fileName: sanitizedFileName,
        data: encryptedData,
        type: LoadFileType.text,
      );
    } catch (e) {
      throw Exception('Failed to download encrypted wallet: $e');
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<void> renameLegacyWallet({
    required String walletId,
    required String newName,
  }) async {
    final String trimmed = newName.trim();
    // Persist to legacy storage
    final List<Map<String, dynamic>> rawLegacyWallets =
        (await _legacyWalletStorage.read(allWalletsStorageKey) as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    bool updated = false;
    for (int i = 0; i < rawLegacyWallets.length; i++) {
      final Map<String, dynamic> data = rawLegacyWallets[i];
      if ((data['id'] as String? ?? '') == walletId) {
        data['name'] = trimmed;
        rawLegacyWallets[i] = data;
        updated = true;
        break;
      }
    }
    if (updated) {
      await _legacyWalletStorage.write(allWalletsStorageKey, rawLegacyWallets);
    }

    // Update in-memory legacy cache if available
    if (_cachedLegacyWallets != null) {
      final index = _cachedLegacyWallets!.indexWhere(
        (element) => element.id == walletId,
      );
      if (index != -1) {
        _cachedLegacyWallets![index] = _cachedLegacyWallets![index].copyWith(
          name: trimmed,
        );
      }
    }
  }
}
