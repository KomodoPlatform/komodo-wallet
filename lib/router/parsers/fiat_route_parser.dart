import 'package:web_dex/router/parsers/base_route_parser.dart';
import 'package:web_dex/router/routes.dart';
import 'package:web_dex/router/state/fiat_state.dart';

class _FiatRouteParser implements BaseRouteParser {
  const _FiatRouteParser();

  @override
  AppRoutePath getRoutePath(Uri uri) {
    if (uri.pathSegments.length == 3) {
      if (uri.pathSegments[1] == 'trading_details' &&
          uri.pathSegments[2].isNotEmpty) {
        return FiatRoutePath.swapDetails(
          FiatAction.tradingDetails,
          uri.pathSegments[2],
        );
      }
    }

    return FiatRoutePath.fiat();
  }
}

const fiatRouteParser = _FiatRouteParser();
