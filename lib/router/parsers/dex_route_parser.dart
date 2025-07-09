import 'package:web_dex/router/parsers/base_route_parser.dart';
import 'package:web_dex/router/routes.dart';
import 'package:web_dex/router/state/dex_state.dart';

class _DexRouteParser implements BaseRouteParser {
  const _DexRouteParser();

  bool handlesDeepLinkParameters(Iterable<String> keys) {
    const dexParams = {
      'from_currency',
      'from_amount',
      'to_currency',
      'to_amount',
      'order_type',
    };

    for (final key in keys) {
      if (dexParams.contains(key)) return true;
    }
    return false;
  }

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
