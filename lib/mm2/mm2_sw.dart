import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:universal_html/js.dart';
import 'package:universal_html/html.dart';
// ignore: unnecessary_import
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/rpc_sw.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/utils/utils.dart';

bool isRunningAsChromeExtension() {
  return kIsWeb &&
      context['chrome'] != null &&
      context['chrome']['runtime'] != null;
}

class MM2Sw extends MM2 implements MM2WithInit {
  final RPCSw _rpc = const RPCSw();

  Future<bool> _mm2IsNotRunning() async {
    final mm2Status = await status();
    return mm2Status == MM2Status.isNotRunningYet;
  }

  @override
  Future<void> init() async {
    if (await _mm2IsNotRunning()) {
      await sendMessage<void>({
        'action': 'init_wasm',
      });
    }

    final html = document.querySelector('html');
    if (html != null) {
      html.classes.remove('loading');
    }
  }

  @override
  Future<void> start(String? passphrase) async {
    final Map<String, dynamic> params = await MM2.generateStartParams(
      passphrase: passphrase,
      gui: 'web_dex web',
      dbDir: null,
      userHome: null,
      mm2Status: await status(),
    );

    if (await _mm2IsNotRunning()) {
      await sendMessage<void>({
        'action': 'run_mm2',
        'params': jsonEncode(params),
        'handle_log': (level, message) {
          _handleLog(level, message);
        },
      });
    }
  }

  @override
  Future<void> stop() async {
    await getStorage().write(rpcPasswordStorageKey, '');

    // todo: consider using FFI instead of RPC here
    await mm2Api.stop();
  }

  @override
  Future<String> version() async {
    return await sendMessage<String>({'action': 'version'});
  }

  @override
  Future<MM2Status> status() async {
    return MM2Status.fromInt(await sendMessage<int>({'action': 'mm2_status'}));
  }

  @override
  Future<dynamic> call(dynamic reqStr) async {
    return await _rpc.call(MM2.prepareRequest(reqStr));
  }

  Future<void> _handleLog(int level, String message) async {
    log(message, path: 'mm2 log');
  }
}
