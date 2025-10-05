import 'package:flutter/material.dart';

/// Visual indicator for PIN/passcode entry progress with animations.
///
/// Displays a row of dots that fill with smooth animations as the user
/// enters their passcode. Provides visual feedback during passcode entry.
///
/// Phase 4: Enhanced with fill animations and scale transitions
class PinDotIndicator extends StatelessWidget {
  const PinDotIndicator({
    required this.length,
    required this.filledCount,
    super.key,
  });

  /// Total number of PIN digits (typically 6)
  final int length;

  /// Number of dots currently filled
  final int filledCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (index) => _AnimatedPinDot(
          key: ValueKey('pin_dot_$index'),
          isFilled: index < filledCount,
          index: index,
        ),
      ),
    );
  }
}

/// Animated PIN dot with fill and scale transitions
class _AnimatedPinDot extends StatefulWidget {
  const _AnimatedPinDot({
    required this.isFilled,
    required this.index,
    super.key,
  });

  final bool isFilled;
  final int index;

  @override
  State<_AnimatedPinDot> createState() => _AnimatedPinDotState();
}

class _AnimatedPinDotState extends State<_AnimatedPinDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _innerDotAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _innerDotAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isFilled) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedPinDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFilled != oldWidget.isFilled) {
      if (widget.isFilled) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isFilled ? _scaleAnimation.value : 1.0,
          child: Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: widget.isFilled
                  ? const Color(0xFF3D77E9)
                  : const Color(0xFF2B2D40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: widget.isFilled
                  ? Transform.scale(
                      scale: _innerDotAnimation.value,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFADAFC4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
