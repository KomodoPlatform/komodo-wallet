import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/shared/utils/utils.dart';

enum WebViewDialogMode {
  dialog,
  fullscreen,
  newTab,
}

class WebViewDialog {
  /// Shows a webview dialog with the given [url] and [title].
  /// The [onConsoleMessage] callback is called with the console messages from
  /// the webview.
  /// The [onCloseWindow] callback is called when the webview is closed.
  /// The [settings] parameter allows you to customize [InAppWebViewSettings]
  /// The [mode] parameter allows you to choose how the webview is shown.
  /// The [width] and [height] parameters allow you to customize the size of the
  /// dialog.
  static Future<void> show(
    BuildContext context, {
    required String url,
    required String title,
    void Function(String)? onConsoleMessage,
    VoidCallback? onCloseWindow,
    InAppWebViewSettings? settings,
    WebViewDialogMode? mode,
    double width = 700,
    double height = 700,
  }) async {
    final webviewSettings = settings ??
        InAppWebViewSettings(
          isInspectable: kDebugMode,
          iframeSandbox: {
            Sandbox.ALLOW_SAME_ORIGIN,
            Sandbox.ALLOW_SCRIPTS,
            Sandbox.ALLOW_FORMS,
            Sandbox.ALLOW_POPUPS,
          },
        );

    final bool isLinux = !kIsWeb && !kIsWasm && Platform.isLinux;
    final bool isWeb = (kIsWeb || kIsWasm) && !isMobile;
    final WebViewDialogMode defaultMode =
        isWeb ? WebViewDialogMode.dialog : WebViewDialogMode.fullscreen;
    final WebViewDialogMode resolvedMode = mode ?? defaultMode;

    // If on Linux, always use newTab mode (open in external browser)
    // `flutter_inappwebview` does not yet support Linux, so use `url_launcher`
    // to launch the URL in the default browser.
    final bool shouldOpenInNewTab =
        resolvedMode == WebViewDialogMode.newTab || isLinux;
    if (shouldOpenInNewTab) {
      await launchURLString(url);
      return;
    }

    if (resolvedMode == WebViewDialogMode.dialog) {
      await showDialog<dynamic>(
        context: context,
        builder: (BuildContext context) {
          return InAppWebviewDialog(
            title: title,
            webviewSettings: webviewSettings,
            onConsoleMessage: onConsoleMessage ?? (_) {},
            onCloseWindow: onCloseWindow,
            url: url,
            width: width,
            height: height,
          );
        },
      );
    } else if (resolvedMode == WebViewDialogMode.fullscreen) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (BuildContext context) {
            return FullscreenInAppWebview(
              title: title,
              webviewSettings: webviewSettings,
              onConsoleMessage: onConsoleMessage ?? (_) {},
              onCloseWindow: onCloseWindow,
              url: url,
            );
          },
        ),
      );
    }
  }
}

class InAppWebviewDialog extends StatelessWidget {
  const InAppWebviewDialog({
    required this.title,
    required this.webviewSettings,
    required this.onConsoleMessage,
    required this.url,
    this.onCloseWindow,
    this.width = 700,
    this.height = 700,
    super.key,
  });

  final String title;
  final InAppWebViewSettings webviewSettings;
  final void Function(String) onConsoleMessage;
  final String url;
  final VoidCallback? onCloseWindow;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  onCloseWindow?.call();
                  Navigator.of(context).pop();
                },
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12.0),
                  bottomRight: Radius.circular(12.0),
                ),
                child: MessageInAppWebView(
                  key: const Key('dialog-inappwebview'),
                  settings: webviewSettings,
                  url: url,
                  onConsoleMessage: onConsoleMessage,
                  onCloseWindow: onCloseWindow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullscreenInAppWebview extends StatelessWidget {
  const FullscreenInAppWebview({
    required this.title,
    required this.webviewSettings,
    required this.onConsoleMessage,
    required this.url,
    this.onCloseWindow,
    super.key,
  });

  final String title;
  final InAppWebViewSettings webviewSettings;
  final void Function(String) onConsoleMessage;
  final String url;
  final VoidCallback? onCloseWindow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            onCloseWindow?.call();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: MessageInAppWebView(
          key: const Key('fullscreen-inapp-webview'),
          settings: webviewSettings,
          url: url,
          onConsoleMessage: onConsoleMessage,
          onCloseWindow: onCloseWindow,
        ),
      ),
    );
  }
}

class MessageInAppWebView extends StatefulWidget {
  const MessageInAppWebView({
    required this.settings,
    required this.onConsoleMessage,
    required this.url,
    this.onCloseWindow,
    super.key,
  });

  final InAppWebViewSettings settings;
  final void Function(String) onConsoleMessage;
  final String url;
  final VoidCallback? onCloseWindow;

  @override
  State<MessageInAppWebView> createState() => _MessageInAppWebviewState();
}

class _MessageInAppWebviewState extends State<MessageInAppWebView> {
  @override
  Widget build(BuildContext context) {
    final urlRequest = URLRequest(url: WebUri(widget.url));
    return InAppWebView(
      key: const Key('flutter-in-app-webview'),
      initialSettings: widget.settings,
      initialUrlRequest: urlRequest,
      onConsoleMessage: _onConsoleMessage,
      onUpdateVisitedHistory: _onUpdateHistory,
      onCloseWindow: (_) {
        widget.onCloseWindow?.call();
      },
      onLoadStop: (controller, url) async {
        await controller.evaluateJavascript(
          source: '''
              window.removeEventListener("message", window._komodoMsgListener, false);
              window._komodoMsgListener = function(event) {
                let messageData;
                try {
                  messageData = JSON.parse(event.data);
                } catch (parseError) {
                  messageData = event.data;
                }

                try {
                  console.log('Received postMessage:', messageData, 'from', event.origin);
                } catch (postError) {
                  console.error('Error posting message', postError);
                }
              };
              window.addEventListener("message", window._komodoMsgListener, false);
            ''',
        );
      },
    );
  }

  void _onConsoleMessage(_, ConsoleMessage consoleMessage) {
    widget.onConsoleMessage(consoleMessage.message);
  }

  void _onUpdateHistory(
    InAppWebViewController controller,
    WebUri? url,
    bool? isReload,
  ) {
    if (url.toString() == 'https://app.komodoplatform.com/') {
      Navigator.of(context).pop();
    }
  }
}
