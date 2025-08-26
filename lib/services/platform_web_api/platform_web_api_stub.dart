import 'dart:async';

import 'platform_web_api.dart';

/// Stub implementation of PlatformWebApi for non-web platforms
class PlatformWebApiStub implements PlatformWebApi {
  @override
  void setElementDisplay(String elementId, String display) {
    // No-op for non-web platforms
  }

  @override
  void addElementClass(String elementId, String className) {
    // No-op for non-web platforms
  }

  @override
  void removeElement(String elementId) {
    // No-op for non-web platforms
  }

  @override
  StreamSubscription<void> onPopState(void Function() callback) {
    // Return a dummy subscription that does nothing
    return Stream<void>.empty().listen((_) {});
  }
}

/// Creates the stub platform implementation for non-web platforms
PlatformWebApi createPlatformWebApi() => PlatformWebApiStub();
