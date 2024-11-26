import 'package:komodo_defi_framework/komodo_defi_framework.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/mm2/mm2_api/rpc/get_my_peer_id/get_my_peer_id_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/version/version_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/version/version_response.dart';
import 'package:web_dex/shared/utils/password.dart';
import 'package:web_dex/shared/utils/utils.dart';

final MM2 mm2 = MM2();

final class MM2 {
  MM2() {
    final String newRpcPassword = generatePassword();

    if (!validateRPCPassword(newRpcPassword)) {
      log(
        "If you're seeing this, there's a bug in the rpcPassword generation code.",
        path: 'auth_bloc => _startMM2',
      );
      throw Exception('invalid rpc password');
    }
    _rpcPassword = newRpcPassword;
  }
  late final String _rpcPassword;
  late final KomodoDefiFramework _kdf;

  Future<bool> isSignedIn() => _kdf.isRunning();

  Future<void> init() async {
    final hostConfig = LocalConfig(rpcPassword: _rpcPassword, https: false);
    final startupConfig = await KdfStartupConfig.noAuthStartup(
      rpcPassword: _rpcPassword,
    );

    _kdf = KomodoDefiFramework.create(hostConfig: hostConfig);
    _kdf.startKdf(startupConfig);
  }

  Future<void> start({
    String? passphrase,
    String? walletName,
    String? walletPassword,
  }) async {
    if (passphrase == null) {
      log('Passpharse is null, and SDK is already initialised, '
              'so skipping KDF start call')
          .ignore();
      return;
    }

    if (await _kdf.isRunning()) {
      await _kdf.kdfStop();
    }

    final startupConfig = await KdfStartupConfig.generateWithDefaults(
      walletName: walletName ?? '',
      walletPassword: walletPassword ?? '',
      enableHd: false,
      rpcPassword: _rpcPassword,
      seed: passphrase,
    );
    await _kdf.startKdf(startupConfig);
  }

  Future<void> stop() async {
    await _kdf.kdfStop();
  }

  Future<String> version() async {
    final JsonMap responseJson = await call(VersionRequest());
    final VersionResponse response = VersionResponse.fromJson(responseJson);

    return response.result;
  }

  Future<bool> isLive() async {
    try {
      final JsonMap response = await call(GetMyPeerIdRequest());
      return (response['result'] as String?)?.isNotEmpty ?? false;
    } catch (e, s) {
      log(
        'Get my peer id error: $e',
        path: 'mm2 => isLive',
        trace: s,
        isError: true,
      ).ignore();
      return false;
    }
  }

  Future<JsonMap> call(dynamic request) async {
    final dynamic requestWithUserpass = _assertPass(request);
    final JsonMap jsonRequest = requestWithUserpass is Map
        ? JsonMap.from(requestWithUserpass)
        // ignore: avoid_dynamic_calls
        : (requestWithUserpass?.toJson != null
            // ignore: avoid_dynamic_calls
            ? requestWithUserpass.toJson() as JsonMap
            : requestWithUserpass as JsonMap);

    final response = await _kdf.client.executeRpc(jsonRequest);
    return _deepConvertMap(response as Map);
  }

  /// Recursively converts the provided map to JsonMap. This is required, as
  /// many of the responses received from the sdk are
  /// LinkedHashMap<Object?, Object?>
  Map<String, dynamic> _deepConvertMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (value is Map) return MapEntry(key.toString(), _deepConvertMap(value));
      if (value is List) {
        return MapEntry(key.toString(), _deepConvertList(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  List<dynamic> _deepConvertList(List<dynamic> list) {
    return list.map((value) {
      if (value is Map) return _deepConvertMap(value);
      if (value is List) return _deepConvertList(value);
      return value;
    }).toList();
  }

  // this is a necessary evil for now becuase of the RPC models that override
  // or use the `late String? userpass` field, which would require refactoring
  // most of the RPC models and directly affected code.
  dynamic _assertPass(dynamic req) {
    if (req is List) {
      for (final dynamic element in req) {
        // ignore: avoid_dynamic_calls
        element.userpass = _rpcPassword;
      }
    } else {
      if (req is Map) {
        req['userpass'] = _rpcPassword;
      } else {
        // ignore: avoid_dynamic_calls
        req.userpass = _rpcPassword;
      }
    }

    return req;
  }
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
