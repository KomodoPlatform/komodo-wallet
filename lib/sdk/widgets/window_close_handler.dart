import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/utils/window/window.dart';

/// A widget that handles window close events and SDK disposal across all platforms.
///
/// This widget uses [AppLifecycleListener] to intercept application exit events
/// across all platforms and shows a confirmation dialog before exiting. On the
/// web, it also registers a `beforeunload` message using
/// [showMessageBeforeUnload].
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

class _WindowCloseHandlerState extends State<WindowCloseHandler> {
  /// Tracks if the SDK has been disposed to prevent multiple disposal attempts
  bool _hasSdkBeenDisposed = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      showMessageBeforeUnload(
          'This will close Komodo Wallet and stop all trading activities.');
    }
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        print('Window close handler: exit requested');
        final shouldExit = await _handleWindowClose();
        return shouldExit ? AppExitResponse.exit : AppExitResponse.cancel;
      },
      onStateChange: (state) {
        if (state == AppLifecycleState.detached) {
          _disposeSDKIfNeeded();
        }
      },
    );
    return;
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
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
