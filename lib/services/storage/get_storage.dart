import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_dex/services/storage/app_storage.dart';
import 'package:web_dex/services/storage/base_storage.dart';
import 'package:web_dex/services/storage/mock_storage.dart';

final BaseStorage _storage = kIsWeb ||
        Platform.isWindows ||
        !Platform.environment.containsKey('FLUTTER_TEST')
    ? AppStorage()
    : MockStorage();

BaseStorage getStorage() {
  return _storage;
}
