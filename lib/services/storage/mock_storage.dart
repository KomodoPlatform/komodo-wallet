import 'package:komodo_wallet/services/storage/base_storage.dart';

class MockStorage implements BaseStorage {
  @override
  Future<bool> delete(String key) {
    return Future.value(true);
  }

  @override
  Future<dynamic> read(String key) {
    return Future<String>.value(key);
  }

  @override
  Future<bool> write(String key, dynamic data) {
    return Future<bool>.value(true);
  }
}
