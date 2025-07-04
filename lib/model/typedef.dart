import 'package:komodo_wallet/model/coin.dart';

/// [Ticker] is a part of coin abbr without protocol sufix,
/// e.g. `KMD` for `KMD-BEP20`
/// See also: [abbr2Ticker] helper
typedef Ticker = String;
typedef Coins = List<Coin>;
typedef CoinsByTicker = Map<Ticker, Coins>;
