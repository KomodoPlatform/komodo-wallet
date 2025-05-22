import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/analytics/events/user_engagement_events.dart';
import 'package:web_dex/services/platform_info/plaftorm_info.dart';

/// A widget that handles analytics lifecycle events like app opened/resumed.
///
/// This widget tracks application lifecycle state changes and logs analytics events
/// when the app is opened initially or resumed from background.
class AnalyticsLifecycleHandler extends StatefulWidget {
  /// Creates an AnalyticsLifecycleHandler.
  ///
  /// The [child] parameter must not be null.
  const AnalyticsLifecycleHandler({
    super.key,
    required this.child,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<AnalyticsLifecycleHandler> createState() =>
      _AnalyticsLifecycleHandlerState();
}

class _AnalyticsLifecycleHandlerState extends State<AnalyticsLifecycleHandler>
    with WidgetsBindingObserver {
  /// Tracks if the app opened event has been initialized
  bool _isInitialized = false;

  /// Number of failed attempts to log the app opened event
  int _retryCount = 0;

  /// Maximum number of retry attempts
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't call _logAppOpened() here to avoid accessing AnalyticsBloc before it's ready
    // Instead, we'll do it in didChangeDependencies after the widget tree is built
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only log app opened after the widget tree is fully built and AnalyticsBloc is available
    if (!_isInitialized) {
      // Use Future.microtask to ensure this runs after the current frame is completed
      Future.microtask(() {
        _logAppOpened();
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only try to log if the bloc is available (widget tree is built)
      if (_isInitialized) {
        _logAppOpened();
      }
    }
  }

  /// Logs an app opened analytics event.
  ///
  /// This method attempts to find the AnalyticsBloc in the widget tree and dispatch
  /// an app opened event. If the bloc isn't available, it will retry a limited number
  /// of times with a short delay between attempts.
  void _logAppOpened() {
    try {
      // Check if context is still valid
      if (!mounted) return;

      // Make sure we have a valid BuildContext that can access the AnalyticsBloc
      if (context
              .findAncestorWidgetOfExactType<BlocProvider<AnalyticsBloc>>() !=
          null) {
        try {
          final analyticsBloc = context.read<AnalyticsBloc>();
          final platform = PlatformInfo.getInstance().platform;
          final appVersion = packageInformation.packageVersion ?? 'unknown';

          analyticsBloc.add(
            AnalyticsAppOpenedEvent(
              platform: platform,
              appVersion: appVersion,
            ),
          );

          // Reset retry count on success
          _retryCount = 0;
        } catch (e) {
          // Log error but don't crash the app if analytics fails
          debugPrint('Error accessing AnalyticsBloc: $e');
          _scheduleRetry();
        }
      } else {
        // If we can't find the AnalyticsBloc provider, it means the widget tree
        // structure doesn't allow us to access it yet. Schedule a retry.
        _scheduleRetry();
      }
    } catch (e) {
      // Log error but don't crash the app if analytics fails
      debugPrint('Error logging app open: $e');
    }
  }

  /// Schedules a retry attempt to log the app opened event
  void _scheduleRetry() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      final delay = Duration(milliseconds: 300 * _retryCount);
      Future.delayed(delay, () {
        if (mounted) _logAppOpened();
      });
    } else {
      debugPrint('Failed to log app open event after $_maxRetries attempts');
    }
  }

  @override
  Widget build(BuildContext context) {
    // We wrap the child in a Builder to ensure we get a new BuildContext
    // that has access to the BlocProvider of AnalyticsBloc after it's created
    return Builder(
      builder: (innerContext) {
        // Only attempt to check for AnalyticsBloc if we're initialized
        if (_isInitialized) {
          try {
            // This is just to verify the bloc exists but we won't use it here
            innerContext.read<AnalyticsBloc>();
          } catch (e) {
            // If the bloc isn't available yet, that's okay
          }
        }
        return widget.child;
      },
    );
  }
}
