import 'package:universal_html/html.dart';
import 'package:komodo_wallet/services/platform_info/plaftorm_info.dart';
import 'package:komodo_wallet/shared/utils/browser_helpers.dart';

class WebPlatformInfo extends PlatformInfo with MemoizedPlatformInfoMixin {
  BrowserInfo? _browserInfo;

  BrowserInfo get browserInfo => _browserInfo ??= BrowserInfoParser.get();

  @override
  // Exclude for mav compilation because it shows string is nullable
  // ignore: unnecessary_non_null_assertion
  String computeOsLanguage() => window.navigator.language!;

  @override
  String computePlatform() =>
      '${browserInfo.os} ${browserInfo.browserName} ${browserInfo.browserVersion}';

  @override
  String? computeScreenSize() => browserInfo.screenSize;
}
