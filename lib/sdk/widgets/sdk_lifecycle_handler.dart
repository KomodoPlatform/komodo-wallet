import 'package:flutter/widgets.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/shared/utils/utils.dart';

/// A widget that handles SDK lifecycle events, particularly cleanup on app termination.
///
/// This widget tracks application lifecycle state changes and ensures that the
/// KomodoDefiSdk is properly disposed when the app is terminated or detached.
///
/// Uses Flutter's managed lifecycle patterns for clean and reliable SDK cleanup.
class SdkLifecycleHandler extends StatefulWidget {
  /// Creates an SdkLifecycleHandler.
  ///
  /// The [child] parameter must not be null.
  const SdkLifecycleHandler({
    super.key,
    required this.child,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<SdkLifecycleHandler> createState() => _SdkLifecycleHandlerState();
}

class _SdkLifecycleHandlerState extends State<SdkLifecycleHandler>
    with WidgetsBindingObserver {
  /// Tracks if the SDK has been disposed to prevent multiple disposal attempts
  bool _hasSdkBeenDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeSDKIfNeeded();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Dispose SDK when app is terminated or detached from UI
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      _disposeSDKIfNeeded();
    }
  }

  /// Disposes the SDK if it hasn't been disposed already.
  Future<void> _disposeSDKIfNeeded() async {
    if (!_hasSdkBeenDisposed) {
      _hasSdkBeenDisposed = true;

      try {
        // Dispose the SDK asynchronously but don't await it in case the app
        // is being forcefully terminated
        await mm2.dispose();

        log('SDK lifecycle handler: initiated SDK disposal');
      } catch (e) {
        log('SDK lifecycle handler: error during SDK disposal - $e',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
