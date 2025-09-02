import 'package:flutter/widgets.dart';

/// Controller that tracks whether the current UI subtree is considered
/// screenshot-sensitive.
class ScreenshotSensitivityController extends ChangeNotifier {
  int _depth = 0;

  bool get isSensitive => _depth > 0;

  void enter() {
    _depth += 1;
    notifyListeners();
  }

  void exit() {
    if (_depth > 0) {
      _depth -= 1;
      notifyListeners();
    }
  }
}

/// Inherited notifier providing access to the ScreenshotSensitivityController.
class ScreenshotSensitivity extends InheritedNotifier<ScreenshotSensitivityController> {
  const ScreenshotSensitivity({
    super.key,
    required ScreenshotSensitivityController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ScreenshotSensitivityController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ScreenshotSensitivity>()?.notifier;
  }

  static ScreenshotSensitivityController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'ScreenshotSensitivity not found in widget tree');
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ScreenshotSensitivity.maybeOf(context);
    if (!identical(controller, _controller)) {
      _controller?.exit();
      _controller = controller;
      _controller?.enter();
    }
  }

  @override
  void dispose() {
    _controller?.exit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

extension ScreenshotSensitivityContextExt on BuildContext {
  bool get isScreenshotSensitive =>
      ScreenshotSensitivity.maybeOf(this)?.isSensitive ?? false;
}

