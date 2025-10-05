import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Accessibility helpers for onboarding flow
///
/// Phase 4: Provides screen reader support, keyboard navigation,
/// and semantic labels for improved accessibility.
class AccessibilityHelpers {
  /// Announce message to screen readers
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Check if screen reader is enabled
  static bool isScreenReaderEnabled(BuildContext context) {
    final data = MediaQuery.of(context);
    return data.accessibleNavigation;
  }

  /// Check if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    final data = MediaQuery.of(context);
    return data.highContrast;
  }

  /// Get text scale factor
  static double getTextScaleFactor(BuildContext context) {
    final data = MediaQuery.of(context);
    return data.textScaleFactor;
  }
}

/// Accessible button with semantic labels and keyboard support
///
/// Phase 4: Button component with full accessibility support
class AccessibleButton extends StatefulWidget {
  const AccessibleButton({
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.enabled = true,
    this.focusNode,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: Focus(
        focusNode: _focusNode,
        onKey: (node, event) {
          if (event is RawKeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            if (widget.onPressed != null && widget.enabled) {
              widget.onPressed!();
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          decoration: _isFocused
              ? BoxDecoration(
                  border: Border.all(color: const Color(0xFF3D77E9), width: 2),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Accessible form field with proper semantic labels
///
/// Phase 4: Text field with accessibility support
class AccessibleFormField extends StatelessWidget {
  const AccessibleFormField({
    required this.controller,
    required this.labelText,
    this.hintText,
    this.semanticLabel,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.nextFocusNode,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? semanticLabel;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? labelText,
      textField: true,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(labelText: labelText, hintText: hintText),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: (_) {
          if (nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          }
        },
      ),
    );
  }
}

/// Accessible step indicator for onboarding progress
///
/// Phase 4: Progress indicator with screen reader support
class AccessibleStepIndicator extends StatelessWidget {
  const AccessibleStepIndicator({
    required this.currentStep,
    required this.totalSteps,
    this.stepNames,
    super.key,
  });

  final int currentStep;
  final int totalSteps;
  final List<String>? stepNames;

  @override
  Widget build(BuildContext context) {
    final stepName = stepNames != null && currentStep < stepNames!.length
        ? stepNames![currentStep]
        : 'Step ${currentStep + 1}';

    return Semantics(
      label: '$stepName of $totalSteps',
      value: '${currentStep + 1} of $totalSteps',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? const Color(0xFF3D77E9)
                    : const Color(0xFF2B2D40),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// High contrast theme detector and provider
///
/// Phase 4: Detect and adapt to high contrast mode
class HighContrastAwareWidget extends StatelessWidget {
  const HighContrastAwareWidget({
    required this.normalChild,
    required this.highContrastChild,
    super.key,
  });

  final Widget normalChild;
  final Widget highContrastChild;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityHelpers.isHighContrastEnabled(context);
    return isHighContrast ? highContrastChild : normalChild;
  }
}

/// Accessible icon button with semantic label
///
/// Phase 4: Icon button with full accessibility support
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.focusNode,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final String? tooltip;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip ?? semanticLabel,
        focusNode: focusNode,
      ),
    );
  }
}

/// Keyboard navigation helper
///
/// Phase 4: Helper for managing keyboard focus order
class KeyboardNavigationHelper {
  /// Create focus nodes for a form
  static List<FocusNode> createFocusNodes(int count) {
    return List.generate(count, (_) => FocusNode());
  }

  /// Dispose focus nodes
  static void disposeFocusNodes(List<FocusNode> nodes) {
    for (final node in nodes) {
      node.dispose();
    }
  }

  /// Move focus to next field
  static void moveToNext(
    BuildContext context,
    FocusNode currentNode,
    FocusNode nextNode,
  ) {
    currentNode.unfocus();
    FocusScope.of(context).requestFocus(nextNode);
  }

  /// Move focus to previous field
  static void moveToPrevious(BuildContext context, FocusNode previousNode) {
    FocusScope.of(context).requestFocus(previousNode);
  }
}

/// Font scaling support widget
///
/// Phase 4: Ensures text scales appropriately with system settings
class ScalableText extends StatelessWidget {
  const ScalableText(
    this.text, {
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        textScaleFactor: MediaQuery.textScaleFactorOf(context).clamp(0.8, 1.5),
      ),
    );
  }
}
