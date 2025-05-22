import 'package:flutter/material.dart';

/// Button type enum to differentiate between different Material Design button types
enum ButtonType {
  /// Text button with minimum width of 64dp, height of 36dp
  text,

  /// Contained or outlined button with minimum width of 88dp, height of 36dp
  containedOrOutlined,

  /// Icon button with touch target of 48x48dp
  icon
}

/// Utility functions for buttons
class ButtonUtils {
  /// Get the constraints for a button based on its type and configuration
  static BoxConstraints getButtonConstraints({
    double? width,
    double? height,
    ButtonType buttonType = ButtonType.containedOrOutlined,
    bool shouldEnforceMinimumSize = false,
    bool expandToFillParent = false,
  }) {
    // For backward compatibility, if explicit dimensions are provided or
    // we're not enforcing minimum size, use the provided dimensions directly
    if (!shouldEnforceMinimumSize || (width != null && height != null)) {
      if (width != null && height != null) {
        return BoxConstraints.tightFor(width: width, height: height);
      } else if (width != null) {
        return BoxConstraints(minWidth: width);
      } else if (height != null) {
        return BoxConstraints(minHeight: height);
      } else if (expandToFillParent) {
        // If we're expanding to fill parent and no other constraints are set,
        // make sure we at least apply minimum height
        return const BoxConstraints(minHeight: 36);
      } else {
        return const BoxConstraints();
      }
    }

    // Only apply Material Design minimum dimensions for flexible constructors
    // when shouldEnforceMinimumSize is true
    double minWidth;
    double minHeight;

    // Determine minimum dimensions based on button type
    switch (buttonType) {
      case ButtonType.text:
        minWidth = 64;
        minHeight = 36;
        break;
      case ButtonType.containedOrOutlined:
        minWidth = 88;
        minHeight = 36;
        break;
      case ButtonType.icon:
        minWidth = 48;
        minHeight = 48;
        break;
    }

    // For flexible constructors, use constraints that allow the button to grow
    // beyond the minimum dimensions while still respecting the minimums
    if (expandToFillParent) {
      return BoxConstraints(
        minWidth: double.infinity,
        minHeight: minHeight,
      );
    } else {
      return BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      );
    }
  }
}
