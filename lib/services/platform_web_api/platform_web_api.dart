import 'dart:async';

import 'platform_web_api_implementation.dart'
    if (dart.library.js_interop) 'platform_web_api_web.dart'
    if (dart.library.io) 'platform_web_api_stub.dart';

/// Abstract interface for platform-specific web APIs
// TODO: Refactor to keep this more abstract and less platform-specific so that
// we can implement equivalent functionality across platforms.
abstract class PlatformWebApi {
  /// Get an element by its ID and set its display style
  void setElementDisplay(String elementId, String display);

  /// Get an element by its ID and add a CSS class
  void addElementClass(String elementId, String className);

  /// Get an element by its ID and remove it from the DOM
  void removeElement(String elementId);

  /// Listen to browser navigation popstate events
  StreamSubscription<void> onPopState(void Function() callback);

  /// Factory constructor that returns the appropriate implementation
  factory PlatformWebApi() => createPlatformWebApi();
}
