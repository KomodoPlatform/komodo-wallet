import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_dex/bloc/bitrefill/bloc/bitrefill_bloc.dart';
import 'package:web_dex/views/bitrefill/bitrefill_button_view.dart';

/// A button that opens the provided url in an embedded InAppWebview widget.
/// This widget uses the flutter_inappwebview package to open the url using
/// platform-specific webview implementations to embed the website inside a
/// widget.
///
/// NOTE: this widget only works on Web, Android, iOS, and macOS (for now).
class BitrefillInAppWebviewButton extends StatefulWidget {
  /// [onMessage] is called when a message is received from the webview.
  /// The [enabled] property determines if the button is clickable.
  /// The [windowTitle] property is used as the title of the window.
  /// The [url] property is the URL to open in the window.
  const BitrefillInAppWebviewButton({
    required this.url,
    required this.windowTitle,
    required this.enabled,
    required this.onMessage,
    super.key,
  });

  /// The title of the pop-up browser window.
  final String windowTitle;

  /// The URL to open in the pop-up browser window.
  final String url;

  /// Determines if the button is enabled.
  final bool enabled;

  /// The callback function that is called when a message is received from the
  /// webview as a console message.
  final dynamic Function(String) onMessage;

  @override
  BitrefillInAppWebviewButtonState createState() =>
      BitrefillInAppWebviewButtonState();
}

class BitrefillInAppWebviewButtonState
    extends State<BitrefillInAppWebviewButton> {
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    iframeAllow: 'same-origin; popups; scripts; forms',
    iframeAllowFullscreen: false,
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<BitrefillBloc, BitrefillState>(
      listener: (BuildContext context, BitrefillState state) {
        if (state is BitrefillPaymentInProgress) {
          // Close the browser window when a payment is in progress.
        }
      },
      child: BitrefillButtonView(
        onPressed: widget.enabled ? _openDialog : null,
      ),
    );
  }

  Future<void> _openDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width * 0.8;
        final height = size.height * 0.8;

        return AlertDialog(
          title: const Text('Bitrefill'),
          content: SizedBox(
            width: width,
            height: height,
            child: Column(
              children: [
                Expanded(
                  child: InAppWebView(
                    key: const Key('bitrefill-inappwebview'),
                    initialUrlRequest: _createUrlRequest(),
                    initialSettings: settings,
                    onWebViewCreated: _onCreated,
                    onConsoleMessage: _onConsoleMessage,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ignore: use_setters_to_change_properties
  void _onCreated(InAppWebViewController controller) {
    webViewController = controller;
  }

  void _onConsoleMessage(
    InAppWebViewController controller,
    ConsoleMessage consoleMessage,
  ) {
    widget.onMessage(consoleMessage.message);
  }

  URLRequest _createUrlRequest() {
    return URLRequest(url: WebUri(widget.url));
  }
}
