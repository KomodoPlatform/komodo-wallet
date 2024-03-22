import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/mm2/mm2_android.dart';
import 'package:web_dex/mm2/mm2_api/rpc/get_my_peer_id/get_my_peer_id_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/version/version_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/version/version_response.dart';
import 'package:web_dex/mm2/mm2_ios.dart';
import 'package:web_dex/mm2/mm2_linux.dart';
import 'package:web_dex/mm2/mm2_macos.dart';
import 'package:web_dex/mm2/mm2_sw.dart';
import 'package:web_dex/mm2/mm2_web.dart';
import 'package:web_dex/mm2/mm2_windows.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/utils/password.dart';
import 'package:web_dex/shared/utils/utils.dart';

final MM2 mm2 = _createMM2();
const rpcPasswordStorageKey = 'cachedRpcPassword';

abstract class MM2 {
  const MM2();
  static late String _rpcPassword;

  Future<void> start(String? passphrase);

  Future<void> stop();

  Future<String> version() async {
    final dynamic responseStr = await call(VersionRequest());
    final Map<String, dynamic> responseJson = jsonDecode(responseStr);
    final VersionResponse response = VersionResponse.fromJson(responseJson);

    return response.result;
  }

  Future<bool> isLive() async {
    try {
      final String response = await call(GetMyPeerIdRequest());
      final Map<String, dynamic> responseJson = jsonDecode(response);

      return responseJson['result']?.isNotEmpty ?? false;
    } catch (e, s) {
      log(
        'Get my peer id error: ${e.toString()}',
        path: 'mm2 => isLive',
        trace: s,
        isError: true,
      );
      return false;
    }
  }

  Future<MM2Status> status();

  Future<dynamic> call(dynamic reqStr);

  static String prepareRequest(dynamic req) {
    final String reqStr = jsonEncode(_assertPass(req));
    return reqStr;
  }

  static Future<Map<String, dynamic>> generateStartParams({
    required String gui,
    required String? passphrase,
    required String? userHome,
    required String? dbDir,
    MM2Status? mm2Status,
  }) async {
    String newRpcPassword;

    if (isRunningAsChromeExtension()) {
      final storage = getStorage();

      if (mm2Status == null || mm2Status == MM2Status.isNotRunningYet) {
        newRpcPassword = generatePassword();
        await storage.write(rpcPasswordStorageKey, newRpcPassword);
      } else {
        newRpcPassword = await storage.read(rpcPasswordStorageKey);
      }
    } else {
      newRpcPassword = generatePassword();
    }

    if (!validateRPCPassword(newRpcPassword)) {
      log(
        'If you\'re seeing this, there\'s a bug in the rpcPassword generation code.',
        path: 'auth_bloc => _startMM2',
      );
      throw Exception('invalid rpc password');
    }
    _rpcPassword = newRpcPassword;

    // Use the repository to load the known global coins, so that we can load
    // from the bundled configs OR the storage provider after updates are
    // downloaded from GitHub.
    final List<dynamic> coins = (await coinsRepo.getKnownGlobalCoins())
        .map((e) => e.toJson() as dynamic)
        .toList();

    // Load the stored settings to get the message service config.
    final storedSettings = await SettingsRepository.loadStoredSettings();
    final messageServiceConfig =
        storedSettings.marketMakerBotSettings.messageServiceConfig;

    return {
      'mm2': 1,
      'allow_weak_password': false,
      'rpc_password': _rpcPassword,
      'netid': 8762,
      'coins': coins,
      'gui': gui,
      if (dbDir != null) 'dbdir': dbDir,
      if (userHome != null) 'userhome': userHome,
      if (passphrase != null) 'passphrase': passphrase,
      if (messageServiceConfig != null)
        'message_service_cfg': messageServiceConfig.toJson(),
    };
  }

  static dynamic _assertPass(dynamic req) {
    if (req is List) {
      for (dynamic element in req) {
        element.userpass = _rpcPassword;
      }
    } else {
      if (req is Map) {
        req['userpass'] = _rpcPassword;
      } else {
        req.userpass = _rpcPassword;
      }
    }

    return req;
  }
}

MM2 _createMM2() {
  if (kIsWeb) {
    if (isRunningAsChromeExtension()) {
      return MM2Sw();
    } else {
      return MM2Web();
    }
  } else if (Platform.isMacOS) {
    return MM2MacOs();
  } else if (Platform.isIOS) {
    return MM2iOS();
  } else if (Platform.isWindows) {
    return MM2Windows();
  } else if (Platform.isLinux) {
    return MM2Linux();
  } else if (Platform.isAndroid) {
    return MM2Android();
  }

  throw UnimplementedError();
}

// 0 - MM2 is not running yet.
// 1 - MM2 is running, but no context yet.
// 2 - MM2 is running, but no RPC yet.
// 3 - MM2's RPC is up.
enum MM2Status {
  isNotRunningYet,
  runningWithoutContext,
  runningWithoutRPC,
  rpcIsUp;

  static MM2Status fromInt(int status) {
    switch (status) {
      case 0:
        return isNotRunningYet;
      case 1:
        return runningWithoutContext;
      case 2:
        return runningWithoutRPC;
      case 3:
        return rpcIsUp;
      default:
        return isNotRunningYet;
    }
  }
}

abstract class MM2WithInit {
  Future<void> init();
}
