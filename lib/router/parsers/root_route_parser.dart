import 'package:flutter/material.dart';
import 'package:web_dex/mm2/mm2_sw.dart';
import 'package:web_dex/model/first_uri_segment.dart';
import 'package:web_dex/router/parsers/base_route_parser.dart';
import 'package:web_dex/router/parsers/bridge_route_parser.dart';
import 'package:web_dex/router/parsers/dex_route_parser.dart';
import 'package:web_dex/router/parsers/fiat_route_parser.dart';
import 'package:web_dex/router/parsers/nft_route_parser.dart';
import 'package:web_dex/router/parsers/settings_route_parser.dart';
import 'package:web_dex/router/parsers/wallet_route_parser.dart';
import 'package:web_dex/router/routes.dart';

class RootRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  final Map<String, BaseRouteParser> _parsers = {
    firstUriSegment.wallet: walletRouteParser,
    firstUriSegment.fiat: fiatRouteParser,
    firstUriSegment.dex: dexRouteParser,
    firstUriSegment.bridge: bridgeRouteParser,
    firstUriSegment.nfts: nftRouteParser,
    firstUriSegment.settings: settingsRouteParser,
  };

  @override
  Future<AppRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.uri.path);
    final BaseRouteParser parser = _getRoutParser(uri);

    return parser.getRoutePath(uri);
  }

  @override
  RouteInformation restoreRouteInformation(AppRoutePath configuration) {
    return RouteInformation(uri: Uri.parse(configuration.location));
  }

  BaseRouteParser _getRoutParser(Uri uri) {
    final defaultRouteParser =
        isRunningAsChromeExtension() ? walletRouteParser : dexRouteParser;
    if (uri.pathSegments.isEmpty) return defaultRouteParser;
    return _parsers[uri.pathSegments.first] ?? defaultRouteParser;
  }
}
