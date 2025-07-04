import 'dart:async';

import 'package:komodo_wallet/mm2/mm2_api/mm2_api.dart';
import 'package:komodo_wallet/services/storage/base_storage.dart';
import 'package:komodo_wallet/services/storage/get_storage.dart';

mixin LoggerMetadataMixin {
  String? _apiVersion;
  String? _locale;

  BaseStorage get environmentStorage => getStorage();

  /// Get the current locale from the environment storage.
  /// NB! If the locale is changed after the app is initialized, the change
  /// will not be reflected in the logger metadata until the app is restarted.
  FutureOr<String?> localeName() {
    if (_locale != null) return _locale;

    return Future<String?>(
      () async => _locale =
          await environmentStorage.read('locale').catchError((_) => null),
    );
  }

  FutureOr<String?> apiVersion(Mm2Api mm2Api) {
    if (_apiVersion != null) return _apiVersion;

    return Future<String?>(
      () async => _apiVersion = await mm2Api.version().catchError((_) => null),
    );
  }
}
