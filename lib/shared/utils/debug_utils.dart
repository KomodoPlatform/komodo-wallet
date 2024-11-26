import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc_event.dart';
import 'package:web_dex/bloc/wallets_bloc/wallets_repo.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/import_swaps/import_swaps_request.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';

Future<void> initDebugData(AuthBloc authBloc) async {
  try {
    final String testWalletStr =
        await rootBundle.loadString('assets/debug_data.json');
    final Map<String, dynamic> debugDataJson = jsonDecode(testWalletStr);
    final Map<String, dynamic>? newWalletJson = debugDataJson['wallet'];
    if (newWalletJson == null) {
      return;
    }

    final Wallet? debugWallet = await _createDebugWallet(
      newWalletJson,
      hasBackup: true,
    );
    if (debugWallet == null) {
      return;
    }
    if (newWalletJson['automateLogin'] == true) {
      authBloc.add(AuthReLogInEvent(
        seed: newWalletJson['seed'],
        wallet: debugWallet,
        password: newWalletJson['password'],
      ));
    }
  } catch (e) {
    return;
  }
}

Future<Wallet?> _createDebugWallet(
  Map<String, dynamic> walletJson, {
  bool hasBackup = false,
}) async {
  final wallets = await walletsRepo.getAll();
  final Wallet? existedDebugWallet =
      wallets.firstWhereOrNull((w) => w.name == walletJson['name']);
  if (existedDebugWallet != null) return existedDebugWallet;

  final EncryptionTool encryptionTool = EncryptionTool();
  final String name = walletJson['name'];
  final String seed = walletJson['seed'];
  final String password = walletJson['password'];
  final List<String> activatedCoins =
      List<String>.from(walletJson['activated_coins'] ?? <String>[]);

  final String encryptedSeed = await encryptionTool.encryptData(password, seed);

  final Wallet wallet = Wallet(
    id: const Uuid().v1(),
    name: name,
    config: WalletConfig(
      seedPhrase: encryptedSeed,
      activatedCoins: activatedCoins,
      hasBackup: hasBackup,
    ),
  );
  final bool isSuccess = await walletsRepo.save(wallet);
  return isSuccess ? wallet : null;
}

Future<void> importSwapsData(List<dynamic> swapsJson) async {
  final ImportSwapsRequest request = ImportSwapsRequest(swaps: swapsJson);
  await mm2Api.importSwaps(request);
}

Future<List<dynamic>?> loadDebugSwaps() async {
  final String? testDataStr;
  try {
    testDataStr = await rootBundle.loadString('assets/debug_data.json');
  } catch (e) {
    return null;
  }

  final Map<String, dynamic> debugDataJson = jsonDecode(testDataStr);

  if (debugDataJson['swaps'] == null) return null;
  return debugDataJson['swaps']['import'];
}
