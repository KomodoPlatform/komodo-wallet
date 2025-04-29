import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/shared/utils/utils.dart';

class WebViewDialog {
  static Future<void> show(
    BuildContext context, {
    required String url,
    required String title,
    void Function(String)? onConsoleMessage,
    VoidCallback? onCloseWindow,
    InAppWebViewSettings? settings,
  }) async {
    // `flutter_inappwebview` does not yet support Linux, so use `url_launcher`
    // to launch the URL in the default browser.
    if (!kIsWeb && !kIsWasm && Platform.isLinux) {
      return launchURLString(url);
    }

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

    if (kIsWeb && !isMobile) {
      await showDialog<dynamic>(
        context: context,
        builder: (BuildContext context) {
          return InAppWebviewDialog(
            title: title,
            webviewSettings: webviewSettings,
            onConsoleMessage: onConsoleMessage ?? (_) {},
            onCloseWindow: onCloseWindow,
            url: url,
          );
        },
      );
    } else {
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
    super.key,
  });

  final String title;
  final InAppWebViewSettings webviewSettings;
  final void Function(String) onConsoleMessage;
  final String url;
  final VoidCallback? onCloseWindow;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12.0), // Match your app's corner radius
      ),
      child: SizedBox(
        width: 700,
        height: 700,
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
            window.addEventListener("message", (event) => {
              let messageData;
              try {
                  messageData = JSON.parse(event.data);
              } catch (parseError) {
                  messageData = event.data;
              }

              try {
                const messageString = (typeof messageData === 'object') ? JSON.stringify(messageData) : String(messageData);
                console.log(messageString);
              } catch (postError) {
                  console.error('Error posting message', postError);
              }
            }, false);
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
