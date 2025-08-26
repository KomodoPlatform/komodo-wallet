import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

Future<void> initDebugData(
  AuthBloc authBloc,
  WalletsRepository walletsRepository,
) async {
  try {
    final String testWalletStr = await rootBundle.loadString(
      'assets/debug_data.json',
    );
    final JsonMap debugDataJson = jsonFromString(testWalletStr);
    final JsonMap? newWalletJson = debugDataJson.valueOrNull<JsonMap>('wallet');
    if (newWalletJson == null) {
      return;
    }

    if (newWalletJson.value<bool>('automateLogin') == true) {
      final Wallet? debugWallet = await _createDebugWallet(
        walletsRepository,
        newWalletJson,
        hasBackup: true,
      );
      if (debugWallet == null) {
        return;
      }

      authBloc.add(
        AuthRestoreRequested(
          seed: newWalletJson.value<String>('seed'),
          wallet: debugWallet,
          password: newWalletJson.value<String>("password"),
        ),
      );
    }
  } catch (e) {
    return;
  }
}

Future<Wallet?> _createDebugWallet(
  WalletsRepository walletsBloc,
  JsonMap walletJson, {
  bool hasBackup = false,
}) async {
  final wallets = walletsBloc.wallets;
  final Wallet? existedDebugWallet = wallets
      ?.where((w) => w.name == walletJson.valueOrNull<String>('name'))
      .firstOrNull;
  if (existedDebugWallet != null) return existedDebugWallet;

  final String name = walletJson.valueOrNull<String>('name') ?? '';
  final List<String> activatedCoins = walletJson.value<List<String>>(
    'activated_coins',
  );

  return Wallet(
    id: const Uuid().v1(),
    name: name,
    config: WalletConfig(
      activatedCoins: activatedCoins,
      hasBackup: hasBackup,
      seedPhrase: walletJson.value<String>('seed'),
    ),
  );
}

Future<List<dynamic>?> loadDebugSwaps() async {
  final String? testDataStr;
  try {
    testDataStr = await rootBundle.loadString('assets/debug_data.json');
  } catch (e) {
    return null;
  }

  final JsonMap debugDataJson = jsonFromString(testDataStr);

  if (debugDataJson.valueOrNull<JsonMap>('swaps') == null) return null;
  return debugDataJson.value<JsonMap>('swaps').value<List<dynamic>>('import');
}
