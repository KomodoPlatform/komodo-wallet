import 'package:komodo_wallet/router/parsers/base_route_parser.dart';
import 'package:komodo_wallet/router/routes.dart';

class _SettingsRouteParser implements BaseRouteParser {
  const _SettingsRouteParser();

  @override
  AppRoutePath getRoutePath(Uri uri) {
    if (uri.pathSegments.length < 2) {
      return SettingsRoutePath.root();
    }

    if (uri.pathSegments[1] == 'general') {
      return SettingsRoutePath.general();
    }

    if (uri.pathSegments[1] == 'security') {
      return SettingsRoutePath.security();
    }

    // TODO: Remove since the feedback is now handled by `BetterFeedback`
    if (uri.pathSegments[1] == 'feedback') {
      return SettingsRoutePath.feedback();
    }

    return SettingsRoutePath.root();
  }
}

const settingsRouteParser = _SettingsRouteParser();
