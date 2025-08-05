import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/common/screen.dart';
import 'dart:html' as html;
import 'package:web_dex/router/state/routing_state.dart';

class PopupDispatcher {
  PopupDispatcher({
    this.context,
    this.popupContent,
    this.width,
    this.insetPadding,
    this.contentPadding,
    this.barrierColor,
    this.borderColor,
    this.maxWidth = 640,
    this.barrierDismissible = true,
    this.onDismiss,
  });

  final BuildContext? context;
  final Widget? popupContent;
  final double? width;
  final double maxWidth;
  final bool barrierDismissible;
  final EdgeInsets? insetPadding;
  final EdgeInsets? contentPadding;
  final Color? barrierColor;
  final Color? borderColor;
  final VoidCallback? onDismiss;

  bool _isShown = false;
  bool get isShown => _isShown;

  StreamSubscription<html.PopStateEvent>? _popStreamSubscription;

  Future<void> show() async {
    if (_currentContext == null) return;

    if (_isShown) close();
    _isShown = true;
    final borderColor = this.borderColor;
    _setupDismissibleLogic();

    await showDialog<void>(
      barrierDismissible: barrierDismissible,
      context: _currentContext!,
      barrierColor: theme.custom.dialogBarrierColor,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          insetPadding: insetPadding ??
              EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 40 : 24,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: borderColor != null
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
          contentPadding: contentPadding ??
              EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 30,
                vertical: isMobile ? 26 : 30,
              ),
          children: [
            Container(
              width: width,
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: popupContent,
            )
          ],
        );
      },
    );
    _isShown = false;
    _resetBrowserNavigationToDefault();
    if (onDismiss != null) onDismiss!();
  }

  void close() {
    _resetBrowserNavigationToDefault();
    if (_currentContext == null) return;
    if (_isShown) Navigator.of(_currentContext!).pop();
  }

  void _setupDismissibleLogic() {
    routingState.isBrowserNavigationBlocked = true;
    if (barrierDismissible) {
      if (kIsWeb) {
        _onPopStateSubscriptionWeb();
      }
    }
  }

  void _onPopStateSubscriptionWeb() {
    _popStreamSubscription = html.window.onPopState.listen((_) {
      final navigator = Navigator.of(_currentContext!, rootNavigator: true);
      if (navigator.canPop()) {
        _resetBrowserNavigationToDefault();
        navigator.pop();
      }
    });
  }

  void _resetBrowserNavigationToDefault() {
    routingState.isBrowserNavigationBlocked = false;
    _popStreamSubscription?.cancel();
  }

  BuildContext? get _currentContext => context ?? scaffoldKey.currentContext;
}
