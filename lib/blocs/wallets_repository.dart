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
  })  : _encryptionTool = encryptionTool ?? EncryptionTool(),
        _fileLoader = fileLoader ?? FileLoader.fromPlatform();

  final KomodoDefiSdk _kdfSdk;
  final Mm2Api _mm2Api;
  final BaseStorage _legacyWalletStorage;
  final EncryptionTool _encryptionTool;
  final FileLoader _fileLoader;

  List<Wallet>? _cachedWallets;
  List<Wallet>? get wallets => _cachedWallets;

  Future<List<Wallet>> getWallets() async {
    final legacyWallets = await _getLegacyWallets();

    // TODO: move wallet filtering logic to the SDK
    _cachedWallets = (await _kdfSdk.wallets)
        .where(
          (wallet) =>
              wallet.config.type != WalletType.trezor &&
              !wallet.name.toLowerCase().startsWith(trezorWalletNamePrefix),
        )
        .toList();
    return [..._cachedWallets!, ...legacyWallets];
  }

  Future<List<Wallet>> _getLegacyWallets() async {
    final newVariable =
        await _legacyWalletStorage.read(allWalletsStorageKey) as List?;
    final List<Map<String, dynamic>> json =
        newVariable?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];

    return json
        .map((Map<String, dynamic> w) =>
            Wallet.fromJson(w)..config.isLegacyWallet = true)
        .toList();
  }

  Future<void> deleteWallet(
    Wallet wallet, {
    required String password,
  }) async {
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
      log('Failed to delete wallet: $e',
              path: 'wallet_bloc => deleteWallet', isError: true)
          .ignore();
      rethrow;
    }
  }

  String? validateWalletName(String name) {
    // This shouldn't happen, but just in case.
    if (_cachedWallets == null) {
      getWallets().ignore();
      return null;
    }

    if (_cachedWallets!.firstWhereOrNull((w) => w.name == name) != null) {
      return LocaleKeys.walletCreationExistNameError.tr();
    } else if (name.isEmpty || name.length > 40) {
      return LocaleKeys.walletCreationNameLengthError.tr();
    } else if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name)) {
      return LocaleKeys.walletCreationNameCharactersError.tr();
    }

    return null;
  }

  Future<void> resetSpecificWallet(Wallet wallet) async {
    final coinsToDeactivate = wallet.config.activatedCoins
        .where((coin) => !enabledByDefaultCoins.contains(coin));
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
      final String encryptedData =
          await _encryptionTool.encryptData(password, data);
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
}
