import 'dart:async';
import 'dart:convert';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/blocs/bloc_base.dart';
import 'package:web_dex/model/coin.dart';
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

  Wallet? _wallet;
  // ignore: unnecessary_getters_setters
  Wallet? get wallet => _wallet;
  set wallet(Wallet? wallet) {
    _wallet = wallet;
  }

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

  Future<bool> addCoin(Coin coin) async {
    final String coinAbbr = coin.abbr;
    final Wallet? wallet = this.wallet;
    if (wallet == null) {
      return false;
    }
    if (wallet.config.activatedCoins.contains(coinAbbr)) {
      return false;
    }
    wallet.config.activatedCoins.add(coinAbbr);
    this.wallet = wallet;
    return true;
  }

  Future<bool> removeCoin(String coinAbbr) async {
    final Wallet? wallet = this.wallet;
    if (wallet == null) {
      return false;
    }

    wallet.config.activatedCoins.remove(coinAbbr);
    this.wallet = wallet;
    return true;
  }

  Future<void> downloadCurrentWallet(String password) async {
    final Wallet? wallet = (await _kdfSdk.auth.currentUser)?.wallet;
    if (wallet == null) return;

    final String data = jsonEncode(wallet.config);
    final String encryptedData =
        await _encryptionTool.encryptData(password, data);

    await _fileLoader.save(
      fileName: wallet.name,
      data: encryptedData,
      type: LoadFileType.text,
    );

    await confirmBackup();
    this.wallet = wallet;
  }

  Future<void> confirmBackup() async {
    final Wallet? wallet = (await _kdfSdk.auth.currentUser)?.wallet;
    if (wallet == null || wallet.config.hasBackup) return;

    wallet.config.hasBackup = true;
    await _kdfSdk.confirmSeedBackup();
    this.wallet = wallet;
  }
}
