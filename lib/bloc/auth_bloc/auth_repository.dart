import 'dart:async';

import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/mm2_sw.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/platform/platform.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/utils/utils.dart';

class AuthRepository {
  AuthRepository() {
    // Extension needs to track the RPC status and sync
    // As it runs on both full view and extension view at the same time
    if (isRunningAsChromeExtension()) {
      _initPeriodicRpcCheck();
    }
  }

  final StreamController<AuthorizeMode> _authController =
      StreamController<AuthorizeMode>.broadcast();
  Stream<AuthorizeMode> get authMode => _authController.stream;
  String _cachedRpcPassword = '';
  Timer? _periodicCheckTimer;

  Future<void> logIn(AuthorizeMode mode, [String? seed]) async {
    // For extension, noLogin mode won't start MM2
    if (!isRunningAsChromeExtension() || mode != AuthorizeMode.noLogin) {
      if (isRunningAsChromeExtension()) {
        _cachedRpcPassword = 'selfLogin';
      }

      await _startMM2(seed);

      if (isRunningAsChromeExtension()) {
        _cachedRpcPassword =
            await getStorage().read(rpcPasswordStorageKey) ?? '';
      }

      await waitMM2StatusChange(MM2Status.rpcIsUp, mm2, waitingTime: 60000);
    }

    setAuthMode(mode);
  }

  void setAuthMode(AuthorizeMode mode) {
    _authController.sink.add(mode);
  }

  Future<void> logOut() async {
    if (isRunningAsChromeExtension()) {
      _cachedRpcPassword = '';
    }

    await mm2.stop();
    await waitMM2StatusChange(MM2Status.isNotRunningYet, mm2,
        waitingTime: isRunningAsChromeExtension() ? 250 : 3000);

    setAuthMode(AuthorizeMode.noLogin);
  }

  Future<void> _startMM2(String? seed) async {
    try {
      await mm2.start(seed);
    } catch (e) {
      log('mm2 start error: ${e.toString()}');
      rethrow;
    }
  }

  void _initPeriodicRpcCheck() {
    _periodicCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      String? currentRpcPassword =
          await getStorage().read(rpcPasswordStorageKey);
      if (currentRpcPassword != null &&
          _cachedRpcPassword != 'selfLogin' &&
          currentRpcPassword != _cachedRpcPassword) {
        // RPC password has changed, indicating a login or logout. Refresh the page
        Future.delayed(Duration(seconds: currentRpcPassword == '' ? 0 : 1), () {
          reloadPage();
        });
      }
    });
  }

  void dispose() {
    _authController.close();
    _periodicCheckTimer?.cancel();
  }
}

final AuthRepository authRepo = AuthRepository();
