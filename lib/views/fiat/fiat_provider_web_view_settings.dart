import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Default trusted domains for the WebView content blockers
const List<String> kDefaultTrustedDomainFilters = [
  r'komodo\.banxa\.com.*',
  if (kDebugMode) r'app\.demo\.ramp\.network.*',
  r'app\.ramp\.network.*',
  r'embed\.bitrefill\.com.*',
  if (kDebugMode) r'komodo\.banxa-sandbox\.com.*',
  r'app\.komodoplatform\.com.*',
];

/// Factory methods for creating webview settings for specific providers
class FiatProviderWebViewSettings {
  /// Creates secure webview settings for fiat providers like Banxa, Ramp, etc.
  ///
  /// The [trustedDomainFilters] parameter allows filtering content to only
  /// trusted domains for security.
  static InAppWebViewSettings createSecureProviderSettings({
    List<String> trustedDomainFilters = kDefaultTrustedDomainFilters,
  }) {
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
    return InAppWebViewSettings(
      isInspectable: kDebugMode,
      iframeSandbox: {
        // Required for cookies and localStorage access
        Sandbox.ALLOW_SAME_ORIGIN,
        // Required for dynamic iframe content to load in Banxa and Ramp
        // webviews.
        Sandbox.ALLOW_SCRIPTS,
        // Required for Ramp and Banxa form submissions throughout the KYC
        // and payment process.
        Sandbox.ALLOW_FORMS,
        // Required for Ramp "Check transaction status" button after payment
        // to work.
        Sandbox.ALLOW_POPUPS,
        // Deliberately NOT including ALLOW_TOP_NAVIGATION to prevent
        // parent navigation
      },
      // TODO: revisit & possibly fork repo to add support for more platforms
      // The intended approach only works on iOS and macOS, and is far too restrictive
      // given that we are using 3rd party providers that can change their dependencies at
      // any time (i.e. Ramp)tk
      // contentBlockers: [
      //   // Block all content by default
      //   ContentBlocker(
      //     trigger: ContentBlockerTrigger(urlFilter: '.*'),
      //     action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      //   ),
      //   // Allow the specific domains we trust
      //   ...trustedDomainFilters.map(
      //     (urlFilter) => ContentBlocker(
      //       trigger: ContentBlockerTrigger(urlFilter: urlFilter),
      //       action: ContentBlockerAction(
      //         type: ContentBlockerActionType.IGNORE_PREVIOUS_RULES,
      //       ),
      //     ),
      //   ),
      // ],
    );
  }
}
