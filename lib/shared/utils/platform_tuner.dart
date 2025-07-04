import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:window_size/window_size.dart';

abstract class PlatformTuner {
  static const minDesktopSize = Size(360, 650);
  static const defaultDesktopSize = Size(1200, 820);
  static const maxDesktopSize = Size.infinite;

  static bool get isNativeDesktop {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static bool get isNativeMobile {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> setWindowTitleAndSize() async {
    if (!isNativeDesktop) return;

    setWindowTitle(appTitle);
    await _setWindowSizeDesktop();
  }

  static Future<void> _setWindowSizeDesktop() async {
    final info = await getWindowInfo();
    final double scaleFactor = info.screen?.scaleFactor ?? info.scaleFactor;

    if (defaultTargetPlatform == TargetPlatform.linux && scaleFactor != 1.0) {
      // yurii (09.05.23): there is a bug in the window_size package
      // that prevents the window from being resized correctly on Linux
      // when the scale factor is not 1.
      // setWindowMinSize and setWindowMaxSize are also affected.
      return;
    }

    // https://github.com/google/flutter-desktop-embedding/issues/917
    final double appliedScaleFactor =
        defaultTargetPlatform == TargetPlatform.windows ? scaleFactor : 1.0;

    final Offset center = info.screen?.frame.center ?? info.frame.center;
    final defaultWindowSize = Rect.fromCenter(
      center: center,
      width: defaultDesktopSize.width * appliedScaleFactor,
      height: defaultDesktopSize.height * appliedScaleFactor,
    );

    setWindowMinSize(minDesktopSize);
    setWindowMaxSize(maxDesktopSize);
    setWindowFrame(defaultWindowSize);
  }
}
