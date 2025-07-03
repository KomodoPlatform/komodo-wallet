import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/shared/utils/platform_tuner.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/utils/window/window.dart';

/// A widget that handles window close events and SDK disposal across all platforms.
///
/// This widget uses different strategies based on the platform:
/// - Desktop (Windows, macOS, Linux): Uses flutter_window_close for native window close handling
/// - Web: Uses showMessageBeforeUnload for browser beforeunload event
/// - Mobile (iOS, Android): Uses WidgetsBindingObserver for lifecycle management
///   and PopScope for exit confirmation
///
/// In all cases, it ensures the KomodoDefiSdk is properly disposed when the app is closed.
class WindowCloseHandler extends StatefulWidget {
  /// Creates a WindowCloseHandler.
  ///
  /// The [child] parameter must not be null.
  const WindowCloseHandler({
    super.key,
    required this.child,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<WindowCloseHandler> createState() => _WindowCloseHandlerState();
}

class _WindowCloseHandlerState extends State<WindowCloseHandler>
    with WidgetsBindingObserver {
  /// Tracks if the SDK has been disposed to prevent multiple disposal attempts
  bool _hasSdkBeenDisposed = false;

  @override
  void initState() {
    super.initState();
    _setupCloseHandler();
  }

  /// Sets up the appropriate close handler based on the platform.
  void _setupCloseHandler() {
    if (PlatformTuner.isNativeDesktop) {
      // Desktop platforms: Use flutter_window_close
      FlutterWindowClose.setWindowShouldCloseHandler(() async {
        return await _handleWindowClose();
      });
    } else if (kIsWeb) {
      // Web platform: Use beforeunload event
      showMessageBeforeUnload(
          'This will close Komodo Wallet and stop all trading activities.');
    } else {
      // Mobile platforms: Use lifecycle observer
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Dispose SDK when app is terminated or detached from UI (mobile platforms)
    if (state == AppLifecycleState.detached) {
      _disposeSDKIfNeeded();
    }
  }

  /// Handles the window close event.
  /// Returns true if the window should close, false otherwise.
  Future<bool> _handleWindowClose() async {
    final context =
        scaffoldKey.currentContext ?? (mounted ? this.context : null);

    // Show confirmation dialog
    final shouldClose = (context == null)
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Do you really want to quit?'),
                content: const Text(
                    'This will close Komodo Wallet and stop all trading activities.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              );
            },
          );

    log('Window close handler: User confirmed close - $shouldClose');

    // If user confirmed, dispose the SDK
    if (shouldClose == true) {
      await _disposeSDKIfNeeded();
      return true;
    }

    return false;
  }

  Future<void> _handlePop() async {
    final shouldClose = await _handleWindowClose();
    if (shouldClose) {
      await SystemNavigator.pop();
    }
  }

  /// Disposes the SDK if it hasn't been disposed already.
  Future<void> _disposeSDKIfNeeded() async {
    if (!_hasSdkBeenDisposed) {
      _hasSdkBeenDisposed = true;

      try {
        await mm2.dispose();
        log('Window close handler: SDK disposed successfully');
      } catch (e, s) {
        log('Window close handler: error during SDK disposal - $e');
        log('Stack trace: ${s.toString()}');
      }
    }
  }

  @override
  void dispose() {
    // Clean up based on platform
    if (PlatformTuner.isNativeDesktop) {
      FlutterWindowClose.setWindowShouldCloseHandler(null);
    } else if (!kIsWeb) {
      // Mobile platforms: Remove lifecycle observer
      WidgetsBinding.instance.removeObserver(this);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformTuner.isNativeMobile) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            _handlePop();
          }
        },
        child: widget.child,
      );
    }

    return widget.child;
  }
}
