import 'platform_web_api.dart';
import 'platform_web_api_stub.dart';

/// Creates the appropriate platform-specific implementation
/// This is the default implementation that will be used if no conditional import matches
PlatformWebApi createPlatformWebApi() => PlatformWebApiStub();
