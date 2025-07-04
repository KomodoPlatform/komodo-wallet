import 'package:komodo_wallet/router/parsers/base_route_parser.dart';
import 'package:komodo_wallet/router/routes.dart';
import 'package:komodo_wallet/router/state/dex_state.dart';

class _DexRouteParser implements BaseRouteParser {
  const _DexRouteParser();
  @override
  AppRoutePath getRoutePath(Uri uri) {
    if (uri.pathSegments.length == 3) {
      if (uri.pathSegments[1] == 'trading_details' &&
          uri.pathSegments[2].isNotEmpty) {
        return DexRoutePath.swapDetails(
            DexAction.tradingDetails, uri.pathSegments[2]);
      }
    }

    if (uri.pathSegments.length == 1) {
      return DexRoutePath.dex(
        fromCurrency: uri.queryParameters['from_currency'] ?? '',
        fromAmount: uri.queryParameters['from_amount'] ?? '',
        toCurrency: uri.queryParameters['to_currency'] ?? '',
        toAmount: uri.queryParameters['to_amount'] ?? '',
        orderType: uri.queryParameters['order_type'] ?? '',
      );
    }
    return DexRoutePath.dex();
  }
}

const dexRouteParser = _DexRouteParser();
