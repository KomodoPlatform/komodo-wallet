import 'dart:async';
import 'dart:convert';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/blocs/bloc_base.dart';
import 'package:web_dex/model/kdf_auth_metadata_extension.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';

@Deprecated('Please use AuthBloc or KomodoDefiSdk instead.')
class CurrentWalletBloc implements BlocBase {
  CurrentWalletBloc({
    required KomodoDefiSdk kdfSdk,
    required EncryptionTool encryptionTool,
    required FileLoader fileLoader,
  })  : _encryptionTool = encryptionTool,
        _fileLoader = fileLoader,
        _kdfSdk = kdfSdk;

  final KomodoDefiSdk _kdfSdk;
  final EncryptionTool _encryptionTool;
  final FileLoader _fileLoader;

  @override
  void dispose() {}

  Future<bool> updatePassword(
    String oldPassword,
    String password,
    Wallet wallet,
  ) async {
    // TODO!: re-implement via sdk
    throw UnimplementedError(
      'Update password operation is not currently supported',
    );
  }

  Future<void> downloadCurrentWallet(String password) async {
    final Wallet? wallet = (await _kdfSdk.auth.currentUser)?.wallet;
    if (wallet == null) return;

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

    await _fileLoader.save(
      fileName: wallet.name,
      data: encryptedData,
      type: LoadFileType.text,
    );

    await confirmBackup();
  }

  Future<void> confirmBackup() async {
    final Wallet? wallet = (await _kdfSdk.auth.currentUser)?.wallet;
    if (wallet == null || wallet.config.hasBackup) return;

    wallet.config.hasBackup = true;
    await _kdfSdk.confirmSeedBackup();
  }
}
