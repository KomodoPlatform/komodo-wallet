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
///
/// Uses Flutter's managed lifecycle patterns for clean and reliable event handling.
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
  /// Tracks if the initial app opened event has been logged
  bool _hasLoggedInitialOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Schedule the initial app opened event to be logged after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logAppOpenedEvent();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Log app opened event when app is resumed (but not on initial open)
    if (state == AppLifecycleState.resumed && _hasLoggedInitialOpen) {
      _logAppOpenedEvent();
    }
  }

  /// Logs an app opened analytics event using Flutter's managed context patterns.
  void _logAppOpenedEvent() {
    // Ensure widget is still mounted before accessing context
    if (!mounted) return;

    try {
      // Use context.read to access the bloc - this will throw if not available
      final analyticsBloc = context.read<AnalyticsBloc>();
      final platform = PlatformInfo.getInstance().platform;
      final appVersion = packageInformation.packageVersion ?? 'unknown';

      analyticsBloc.logEvent(
        AppOpenedEventData(
          platform: platform,
          appVersion: appVersion,
        ),
      );

      // Mark that we've successfully logged the initial open
      if (!_hasLoggedInitialOpen) {
        _hasLoggedInitialOpen = true;
      }

      debugPrint('Analytics: App opened event logged successfully');
    } catch (e) {
      // Log the error but don't crash the app
      debugPrint('Analytics: Failed to log app opened event - $e');

      // If this is the initial attempt and failed, we'll try again on next resume
      // Flutter's lifecycle management will handle subsequent attempts naturally
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
