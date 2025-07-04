import 'package:komodo_wallet/router/parsers/base_route_parser.dart';
import 'package:komodo_wallet/router/routes.dart';
import 'package:komodo_wallet/router/state/bridge_section_state.dart';

class _BridgeRouteParser implements BaseRouteParser {
  const _BridgeRouteParser();

  @override
  AppRoutePath getRoutePath(Uri uri) {
    if (uri.pathSegments.length == 3) {
      if (uri.pathSegments[1] == 'trading_details' &&
          uri.pathSegments[2].isNotEmpty) {
        return BridgeRoutePath.swapDetails(
            BridgeAction.tradingDetails, uri.pathSegments[2]);
      }
    }

    return BridgeRoutePath.bridge();
  }
}

const bridgeRouteParser = _BridgeRouteParser();
