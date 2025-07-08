import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';
import 'package:web_dex/analytics/events/user_engagement_events.dart';
import 'package:web_dex/services/platform_info/plaftorm_info.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';

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

  /// Reference to the analytics repository
  late final AnalyticsRepo _analyticsRepo;

  @override
  void initState() {
    super.initState();

    // Get the analytics repository from GetIt
    try {
      _analyticsRepo = GetIt.I<AnalyticsRepo>();
    } catch (e) {
      log('AnalyticsLifecycleHandler: Failed to get AnalyticsRepo - $e');
    }

    WidgetsBinding.instance.addObserver(this);

    // Schedule the initial app opened event to be logged after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logAppOpenedEvent();
      _checkAuthStatus();
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
      _checkAuthStatus();
    }
  }

  /// Logs an app opened analytics event using the analytics repository.
  void _logAppOpenedEvent() {
    try {
      final platform = PlatformInfo.getInstance().platform;
      final appVersion = packageInformation.packageVersion ?? 'unknown';

      _analyticsRepo.queueEvent(
        AppOpenedEventData(
          platform: platform,
          appVersion: appVersion,
        ),
      );

      // Mark that we've successfully logged the initial open
      if (!_hasLoggedInitialOpen) {
        _hasLoggedInitialOpen = true;
      }

      log('Analytics: App opened event logged successfully');
    } catch (e) {
      // Log the error but don't crash the app
      log('Analytics: Failed to log app opened event - $e');

      // If this is the initial attempt and failed, we'll try again on next resume
      // Flutter's lifecycle management will handle subsequent attempts naturally
    }
  }

  void _checkAuthStatus() {
    try {
      context.read<AuthBloc>().add(const AuthLifecycleCheckRequested());
    } catch (e) {
      log('AnalyticsLifecycleHandler: Failed to check auth status - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
