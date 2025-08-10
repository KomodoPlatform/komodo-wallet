library firebase_core;

class FirebaseOptions {
  const FirebaseOptions({
    this.apiKey = '',
    this.appId = '',
    this.messagingSenderId = '',
    this.projectId = '',
    this.authDomain,
    this.databaseURL,
    this.storageBucket,
    this.measurementId,
    this.trackingId,
    this.androidClientId,
    this.iosBundleId,
    this.iosClientId,
    this.iosAppStoreId,
    this.appGroupId,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;

  final String? authDomain;
  final String? databaseURL;
  final String? storageBucket;
  final String? measurementId;
  final String? trackingId;
  final String? androidClientId;
  final String? iosBundleId;
  final String? iosClientId;
  final String? iosAppStoreId;
  final String? appGroupId;
}

class FirebaseApp {
  const FirebaseApp([this.name = '[DEFAULT]', this.options = const FirebaseOptions()]);
  final String name;
  final FirebaseOptions options;
}

class Firebase {
  static final List<FirebaseApp> _apps = <FirebaseApp>[const FirebaseApp()];
  static List<FirebaseApp> get apps => List.unmodifiable(_apps);
  static FirebaseApp app([String name = '[DEFAULT]']) => _apps.first;
  static Future<FirebaseApp> initializeApp({String? name, FirebaseOptions? options}) async {
    return FirebaseApp(name ?? '[DEFAULT]', options ?? const FirebaseOptions());
  }
}