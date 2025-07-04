import 'package:komodo_wallet/bloc/coins_bloc/coins_bloc.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/router/parsers/base_route_parser.dart';
import 'package:komodo_wallet/router/routes.dart';

class WalletRouteParser implements BaseRouteParser {
  const WalletRouteParser(this._coinsBloc);

  final CoinsBloc _coinsBloc;

  @override
  AppRoutePath getRoutePath(Uri uri) {
    if (uri.pathSegments.length < 2) {
      return WalletRoutePath.wallet();
    }
    if (uri.pathSegments[1] == 'add-assets' ||
        uri.pathSegments[1] == 'remove-assets') {
      return WalletRoutePath.action(uri.pathSegments[1]);
    }

    final Coin? coin = _coinsBloc.state.walletCoins[uri.pathSegments[1]];

    return coin == null
        ? WalletRoutePath.wallet()
        : WalletRoutePath.coinDetails(coin.abbr);
  }
}
