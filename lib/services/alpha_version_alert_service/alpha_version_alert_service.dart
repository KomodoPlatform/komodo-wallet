import 'package:flutter/material.dart';
import 'package:komodo_wallet/app_config/package_information.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/dispatchers/popup_dispatcher.dart';
import 'package:komodo_wallet/services/storage/base_storage.dart';
import 'package:komodo_wallet/services/storage/get_storage.dart';
import 'package:komodo_wallet/shared/widgets/alpha_version_warning.dart';

final _serviceStorageKey =
    'alpha_alert_v2_shown_${packageInformation.packageVersion}';

class AlphaVersionWarningService {
  AlphaVersionWarningService() : _storage = getStorage();

  final BaseStorage _storage;
  Future<void> run() async {
    final isShown = await _checkShowingMessageEarlier();
    if (isShown) return;

    PopupDispatcher(
      barrierDismissible: false,
      maxWidth: 320,
      contentPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 26)
          : const EdgeInsets.all(40.0),
      popupContent: AlphaVersionWarning(onAccept: _onAccept),
    ).show();
  }

  Future<bool> _checkShowingMessageEarlier() async {
    return await _storage.read(_serviceStorageKey) ?? false;
  }

  Future<void> _onAccept() async {
    await _storage.write(_serviceStorageKey, true);
  }
}
