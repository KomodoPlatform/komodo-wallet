import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// #644: We want the password to be obscured most of the time
/// in order to workaround the problem of some devices ignoring `TYPE_TEXT_FLAG_NO_SUGGESTIONS`,
/// https://github.com/flutter/engine/blob/d1c71e5206bd9546f4ff64b7336c4e74e3f4ccfd/shell/platform/android/io/flutter/plugin/editing/TextInputPlugin.java#L93-L99
class PasswordVisibilityControl extends StatefulWidget {
  const PasswordVisibilityControl({required this.onVisibilityChange});
  final void Function(bool) onVisibilityChange;

  @override
  State<PasswordVisibilityControl> createState() =>
      _PasswordVisibilityControlState();
}

class _PasswordVisibilityControlState extends State<PasswordVisibilityControl> {
  bool _isObscured = true;
  Offset _tapStartPosition = const Offset(0, 0);
  Timer? _timer;

  void _setObscureTo(bool isObscured) {
    if (!mounted) {
      return;
    }
    _timer?.cancel();
    setState(() {
      _isObscured = isObscured;
    });
    widget.onVisibilityChange(_isObscured);
  }

  bool _wasLongPressMoved(Offset position) {
    final double distance = sqrt(
      pow(_tapStartPosition.dx - position.dx, 2) +
          pow(_tapStartPosition.dy - position.dy, 2),
    );
    return distance > 20;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // NB: Both the long press and the tap start with `onTabDown`.
      onTapDown: (TapDownDetails details) {
        _tapStartPosition = details.globalPosition;
        _setObscureTo(!_isObscured);
      },
      // #644: Most users expect the eye to react to the taps (behaving as a toggle)
      // whereas long press handling starts too late to produce any visible reaction.
      // Flashing the password for a few seconds in order not to befuddle the users.
      onTapUp: (TapUpDetails details) {
        _timer = Timer(const Duration(seconds: 2), () {
          _setObscureTo(true);
        });
      },
      onLongPressStart: (LongPressStartDetails details) {
        _timer?.cancel();
      },
      onLongPressEnd: (LongPressEndDetails details) {
        _setObscureTo(true);
      },

      // #644: Fires when we press on the eye and *a few seconds later* drag the finger off screen.
      onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
        if (_wasLongPressMoved(details.globalPosition)) {
          _setObscureTo(true);
        }
      },
      // #644: Fires when we press on the eye and *immediately* drag the finger off screen.
      onVerticalDragStart: (DragStartDetails details) {
        _setObscureTo(true);
      },
      onHorizontalDragStart: (DragStartDetails details) {
        _setObscureTo(true);
      },

      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        child: SizedBox(
          width: 60,
          child: Icon(
            _isObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
