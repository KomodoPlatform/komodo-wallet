import 'package:komodo_wallet/router/parsers/base_route_parser.dart';
import 'package:komodo_wallet/router/routes.dart';

class _NFTsRouteParser implements BaseRouteParser {
  const _NFTsRouteParser();

  @override
  AppRoutePath getRoutePath(Uri uri) {
    if (uri.pathSegments.length == 2) {
      if (uri.pathSegments[1] == 'receive') {
        return NftRoutePath.nftReceive();
      } else if (uri.pathSegments[1] == 'transactions') {
        return NftRoutePath.nftTransactions();
      } else if (uri.pathSegments[1].isNotEmpty) {
        return NftRoutePath.nftDetails(uri.pathSegments[1], false);
      }
    }

    return NftRoutePath.nfts();
  }
}

const nftRouteParser = _NFTsRouteParser();
