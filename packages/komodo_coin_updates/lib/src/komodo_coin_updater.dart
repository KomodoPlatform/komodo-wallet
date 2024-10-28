import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:komodo_persistence_layer/komodo_persistence_layer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/coin_info.dart';
import 'models/models.dart';

class KomodoCoinUpdater {
  /// Initialises Hive with the path to the app folder. This should be called
  /// before any other operations with this package. If [isWeb] is true, then
  /// [Hive.initFlutter] is called instead of [Hive.init].
  static Future<void> ensureInitialized(
    String appFolder, {
    bool isWeb = false,
  }) async {
    if (isWeb) {
      await Hive.initFlutter(appFolder);
    } else {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String path = p.join(appDir.path, appFolder);
      Hive.init(path);
    }
    initializeAdapters();
  }

  static void ensureInitializedIsolate(String fullAppFolderPath) {
    Hive.init(fullAppFolderPath);
    initializeAdapters();
  }

  static void initializeAdapters() {
    Hive.registerAdapter(AddressFormatAdapter());
    Hive.registerAdapter(CheckPointBlockAdapter());
    Hive.registerAdapter(CoinAdapter());
    Hive.registerAdapter(CoinConfigAdapter());
    Hive.registerAdapter(CoinInfoAdapter());
    Hive.registerAdapter(ConsensusParamsAdapter());
    Hive.registerAdapter(ContactAdapter());
    Hive.registerAdapter(ElectrumAdapter());
    Hive.registerAdapter(LinksAdapter());
    Hive.registerAdapter(NodeAdapter());
    Hive.registerAdapter(PersistedStringAdapter());
    Hive.registerAdapter(ProtocolAdapter());
    Hive.registerAdapter(ProtocolDataAdapter());
    Hive.registerAdapter(RpcUrlAdapter());
  }
}
