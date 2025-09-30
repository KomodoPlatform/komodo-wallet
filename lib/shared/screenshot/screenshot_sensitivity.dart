import 'package:flutter/widgets.dart';

/// Controller that tracks whether the current UI subtree is considered
/// screenshot-sensitive.
class ScreenshotSensitivityController extends ChangeNotifier {
  int _depth = 0;

  bool get isSensitive => _depth > 0;

  void enter() {
    _depth += 1;
    _safeNotifyListeners();
  }

  void exit() {
    if (_depth > 0) {
      _depth -= 1;
      _safeNotifyListeners();
    }
  }

  /// Safely notify listeners, avoiding calls during widget tree locked phases
  /// and calling build during a build or dismount.
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }
}

/// Inherited notifier providing access to the ScreenshotSensitivityController.
class ScreenshotSensitivity
    extends InheritedNotifier<ScreenshotSensitivityController> {
  const ScreenshotSensitivity({
    super.key,
    required ScreenshotSensitivityController controller,
    required super.child,
  }) : super(notifier: controller);

  static ScreenshotSensitivityController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScreenshotSensitivity>()
        ?.notifier;
  }

  static ScreenshotSensitivityController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'ScreenshotSensitivity not found in widget tree',
    );
    return controller!;
  }
}

/// Widget that marks its subtree as screenshot-sensitive while mounted.
class ScreenshotSensitive extends StatefulWidget {
  const ScreenshotSensitive({super.key, required this.child});

  final Widget child;

  @override
  State<ScreenshotSensitive> createState() => _ScreenshotSensitiveState();
}

class _ScreenshotSensitiveState extends State<ScreenshotSensitive> {
  ScreenshotSensitivityController? _controller;
  bool _hasCalledEnter = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ScreenshotSensitivity.maybeOf(context);
    if (!identical(controller, _controller)) {
      // Exit the old controller if we were using it
      if (_hasCalledEnter) {
        _controller?.exit();
      }
      _controller = controller;
      _hasCalledEnter = false;
      // Enter the new controller - this is safe now due to deferred notification
      _controller?.enter();
      _hasCalledEnter = true;
    }
  }

  @override
  void dispose() {
    // Exit the controller - this is safe now due to deferred notification
    if (_hasCalledEnter) {
      _controller?.exit();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

extension ScreenshotSensitivityContextExt on BuildContext {
  bool get isScreenshotSensitive =>
      ScreenshotSensitivity.maybeOf(this)?.isSensitive ?? false;
}
