import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class FocusableWidget extends StatefulWidget {
  const FocusableWidget({
    Key? key,
    required this.child,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);
  final Widget child;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> {
  bool _hasFocus = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: _hasFocus
              ? theme.custom.headerFloatBoxColor
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        onFocusChange: (value) {
          setState(() {
            _hasFocus = value;
          });
        },
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }
}
