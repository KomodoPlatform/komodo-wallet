import 'package:komodo_wallet/bloc/bitrefill/models/embedded_bitrefill_url.dart';
import 'package:komodo_wallet/shared/utils/window/window.dart';

class BitrefillProvider {
  /// A map of supported coin abbreviations to their corresponding Bitrefill
  /// coin names. The keys are the coin abbreviations used in the app, and the
  /// values are the coin names used in the Bitrefill widget.
  Map<String, String> get supportedCoinAbbrMap => <String, String>{
        'BTC': 'bitcoin',
        'BTC-segwit': 'bitcoin',
        'DASH': 'dash',
        'DOGE': 'dogecoin',
        'ETH': 'ethereum',
        'LTC': 'litecoin',
        'LTC-segwit': 'litecoin',
        'USDT-ERC20': 'usdt_erc20',
        'USDT-TRC20': 'usdt_trc20',
        'USDT-PLG20': 'usdt_polygon',
        'USDC-ERC20': 'usdc_erc20',
        'USDC-PLG20': 'usdc_polygon',
      };

  /// A list of supported Bitrefill coin abbreviations for payments.
  List<String> get supportedCoinAbbrs => supportedCoinAbbrMap.keys.toList();

  // TODO: replace with actual Bitrefill referral code / partnership code
  final String referralCode = '2i8u2o27';
  final String theme = 'dark';

  /// Returns the URL of the Bitrefill widget page.
  ///
  /// If the app is running on the web, the URL will be the same as the current
  /// page's origin with the path to the widget's HTML file appended.
  ///
  /// If the app is running on a mobile or desktop platform, the URL will be
  /// the URL of the asset on the deployed web app.
  ///
  /// This is necessary because the Bitrefill widget's content security policy
  /// does not allow the widget to be embedded in an iframe, and the widget
  /// must be embedded in an iframe to work with the app's webview.
  ///
  /// The widget's HTML file is located at `assets/web_pages/bitrefill_widget.html`.
  String embeddedBitrefillUrl({String? coinAbbr, String? refundAddress}) {
    final String baseUrl = baseEmbeddedBitrefillUrl();
    final String? coinName =
        coinAbbr != null ? supportedCoinAbbrMap[coinAbbr] : null;
    final EmbeddedBitrefillUrl embeddedBitrefillUrl = EmbeddedBitrefillUrl(
      baseUrl: baseUrl,
      paymentMethods: coinName != null ? <String>[coinName] : null,
      refundAddress: refundAddress,
      referralCode: referralCode,
      theme: theme,
    );

    return embeddedBitrefillUrl.toString();
  }

  /// Returns the URL of the Bitrefill widget page without any query parameters.
  String baseEmbeddedBitrefillUrl() {
    return '${getOriginUrl()}/assets/assets/'
        'web_pages/bitrefill_widget.html';
  }
}
