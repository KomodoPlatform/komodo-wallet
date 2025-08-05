import 'package:web_dex/model/first_uri_segment.dart';
import 'package:web_dex/router/parsers/base_route_parser.dart';
import 'package:web_dex/router/routes.dart';

/// Route parser for handling staking-related routing
///
/// This parser handles URLs like:
/// - /staking (main staking page)
/// - /staking/atom (staking for specific asset)
class StakingRouteParser extends BaseRouteParser {
  @override
  AppRoutePath getRoutePath(Uri uri) {
    final pathSegments = uri.pathSegments;

    // Handle /staking
    if (pathSegments.length == 1 &&
        pathSegments[0] == firstUriSegment.staking) {
      return StakingRoutePath.staking();
    }

    // Handle /staking/asset_id
    if (pathSegments.length == 2 &&
        pathSegments[0] == firstUriSegment.staking) {
      return StakingRoutePath.asset(pathSegments[1]);
    }

    return StakingRoutePath.staking();
  }

  @override
  bool handlesDeepLinkParameters(Iterable<String> queryParameterKeys) {
    // Staking doesn't handle any special deep link parameters
    return false;
  }
}

/// Global instance of the staking route parser
final StakingRouteParser stakingRouteParser = StakingRouteParser();
