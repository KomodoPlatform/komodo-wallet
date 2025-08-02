import 'package:flutter/material.dart';
import 'package:app_theme/app_theme.dart';
import 'package:web_dex/common/screen.dart';

/// A replacement for the deprecated PopupDispatcher that uses Flutter's built-in dialog system.
///
/// This widget provides the same styling and behavior as PopupDispatcher but with
/// better performance and maintainability.
///
/// ## Migration from PopupDispatcher
///
/// **Simple dialog:**
/// ```dart
/// // OLD
/// PopupDispatcher(
///   context: context,
///   width: 320,
///   popupContent: MyWidget(),
/// ).show();
///
/// // NEW
/// AppDialog.show(
///   context: context,
///   width: 320,
///   child: MyWidget(),
/// );
/// ```
///
/// **Dialog with success callback:**
/// ```dart
/// // OLD
/// _popupDispatcher = PopupDispatcher(
///   context: context,
///   popupContent: MyWidget(onSuccess: () => _popupDispatcher?.close()),
/// );
/// _popupDispatcher?.show();
///
/// // NEW
/// AppDialog.showWithCallback(
///   context: context,
///   childBuilder: (onSuccess) => MyWidget(onSuccess: onSuccess),
/// );
/// ```
///
/// **Dialog with custom styling:**
/// ```dart
/// // OLD
/// PopupDispatcher(
///   context: context,
///   borderColor: customColor,
///   contentPadding: EdgeInsets.all(20),
///   popupContent: MyWidget(),
/// ).show();
///
/// // NEW
/// AppDialog.show(
///   context: context,
///   borderColor: customColor,
///   contentPadding: EdgeInsets.all(20),
///   child: MyWidget(),
/// );
/// ```
class AppDialog {
  /// Shows a dialog with PopupDispatcher-compatible styling.
  ///
  /// Parameters:
  /// - [context]: The build context to show the dialog in
  /// - [child]: The widget to display inside the dialog
  /// - [width]: The preferred width of the dialog content
  /// - [maxWidth]: The maximum width constraint (defaults to 640)
  /// - [barrierDismissible]: Whether the dialog can be dismissed by tapping outside (defaults to true)
  /// - [borderColor]: The color of the dialog border (defaults to theme.custom.specificButtonBorderColor)
  /// - [insetPadding]: Custom inset padding (uses responsive defaults if null)
  /// - [contentPadding]: Custom content padding (uses responsive defaults if null)
  /// - [onDismiss]: Callback called when the dialog is dismissed
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? width,
    double maxWidth = 640,
    bool barrierDismissible = true,
    Color? borderColor,
    EdgeInsets? insetPadding,
    EdgeInsets? contentPadding,
    VoidCallback? onDismiss,
  }) async {
    final result = await showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: theme.custom.dialogBarrierColor,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          insetPadding:
              insetPadding ??
              EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 40 : 24,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: borderColor ?? theme.custom.specificButtonBorderColor,
            ),
          ),
          contentPadding:
              contentPadding ??
              EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 30,
                vertical: isMobile ? 26 : 30,
              ),
          children: [
            Container(
              width: width,
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ],
        );
      },
    );

    // Call onDismiss callback if provided
    if (onDismiss != null) {
      onDismiss();
    }

    return result;
  }

  /// Shows a dialog with a specific content widget and handles success callback.
  ///
  /// This is a convenience method for dialogs that need to close automatically
  /// when a success action occurs.
  static Future<T?> showWithCallback<T>({
    required BuildContext context,
    required Widget Function(VoidCallback onSuccess) childBuilder,
    double? width,
    double maxWidth = 640,
    bool barrierDismissible = true,
    Color? borderColor,
    EdgeInsets? insetPadding,
    EdgeInsets? contentPadding,
    VoidCallback? onDismiss,
    void Function(T?)? onSuccess,
  }) async {
    return show<T>(
      context: context,
      width: width,
      maxWidth: maxWidth,
      barrierDismissible: barrierDismissible,
      borderColor: borderColor,
      insetPadding: insetPadding,
      contentPadding: contentPadding,
      onDismiss: onDismiss,
      child: childBuilder(() {
        // Ensure we pop the dialog from the root navigator. Using the root
        // navigator prevents accidentally popping routes from nested
        // navigators which can lead to a blank screen after login.
        Navigator.of(context, rootNavigator: true).pop();
        if (onSuccess != null) {
          onSuccess(null); // Pass null since we don't have a specific result
        }
      }),
    );
  }
}
