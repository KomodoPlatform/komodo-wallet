import 'dart:async';

import 'package:flutter/material.dart';

class CustomTooltip extends StatefulWidget {
  const CustomTooltip({
    Key? key,
    required this.child,
    required this.tooltip,
    this.scrollController,
    this.maxWidth = 400,
    this.padding = const EdgeInsets.all(8),
    this.boxShadow = const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 5,
        spreadRadius: 1,
        offset: Offset(0, 2),
      )
    ],
    this.color,
  }) : super(key: key);
  final double maxWidth;
  final EdgeInsets padding;
  final Color? color;
  final List<BoxShadow> boxShadow;
  final Widget child;
  final Widget? tooltip;
  final ScrollController? scrollController;

  @override
  State<CustomTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip> {
  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _tooltipKey = GlobalKey();
  bool _tooltipHasHover = false;
  bool _childHasHover = false;
  late OverlayEntry _tooltipWrapper;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _tooltipWrapper = _buildTooltipWrapper();
      widget.scrollController?.addListener(_scrollListener);
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.scrollController?.removeListener(_scrollListener);
    if (_tooltipWrapper.mounted) {
      _tooltipWrapper.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        InkWell(
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          focusColor: Colors.transparent,
          mouseCursor: MouseCursor.uncontrolled,
          key: _childKey,
          onTap: _switch,
          onHover: (hasHover) async {
            setState(() => _childHasHover = hasHover);

            if (_childHasHover) {
              _show();
            } else {
              await Future<dynamic>.delayed(const Duration(milliseconds: 300));
              if (!_tooltipHasHover) _hide();
            }
          },
          child: widget.child,
        ),
      ],
    );
  }

  OverlayEntry _buildTooltipWrapper() {
    final RenderBox childObject =
        _childKey.currentContext?.findRenderObject() as RenderBox;
    final childOffset = childObject.localToGlobal(Offset.zero);
    final bottom = MediaQueryData.fromView(View.of(_childKey.currentContext!))
            .size
            .height -
        childOffset.dy;
    final left = childOffset.dx + childObject.size.width;

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(onTapDown: (details) => _hide()),
            Positioned(
              bottom: bottom,
              left: left,
              width: widget.maxWidth,
              child: Material(
                child: InkWell(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  mouseCursor: MouseCursor.uncontrolled,
                  onTap: () {},
                  onHover: (hasHover) async {
                    setState(() => _tooltipHasHover = hasHover);
                    if (_tooltipHasHover) return;

                    await Future<dynamic>.delayed(
                        const Duration(milliseconds: 300));
                    if (!_childHasHover) _hide();
                  },
                  child: Container(
                    key: _tooltipKey,
                    constraints: BoxConstraints(
                      maxWidth: widget.maxWidth,
                    ),
                    decoration: BoxDecoration(
                      color:
                          widget.color ?? Theme.of(context).colorScheme.surface,
                      boxShadow: widget.boxShadow,
                    ),
                    padding: widget.padding,
                    child: widget.tooltip,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _show() {
    if (widget.tooltip == null) return;
    if (_tooltipWrapper.mounted) return;

    setState(() => _tooltipWrapper = _buildTooltipWrapper());
    Overlay.of(context).insert(_tooltipWrapper);
  }

  void _hide() {
    if (!_tooltipWrapper.mounted) return;

    _tooltipWrapper.remove();
  }

  void _switch() {
    if (_tooltipWrapper.mounted) {
      _hide();
    } else {
      _show();
    }
  }

  void _scrollListener() {
    if (_tooltipWrapper.mounted) {
      _tooltipWrapper.remove();
    }
  }
}
