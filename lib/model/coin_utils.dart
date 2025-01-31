import 'package:collection/collection.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook_depth/orderbook_depth_response.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/typedef.dart';
import 'package:web_dex/shared/utils/utils.dart';

List<Coin> sortFiatBalance(List<Coin> coins) {
  final List<Coin> list = List.from(coins);
  list.sort((a, b) {
    final double usdBalanceA = a.usdBalance ?? 0.00;
    final double usdBalanceB = b.usdBalance ?? 0.00;
    if (usdBalanceA > usdBalanceB) return -1;
    if (usdBalanceA < usdBalanceB) return 1;

    if (a.balance > b.balance) return -1;
    if (a.balance < b.balance) return 1;

    final bool isAEnabled = a.isActive;
    final bool isBEnabled = b.isActive;
    if (isAEnabled && !isBEnabled) return -1;
    if (isBEnabled && !isAEnabled) return 1;

    return a.abbr.compareTo(b.abbr);
  });
  return list;
}

List<Coin> removeWalletOnly(List<Coin> coins) {
  final List<Coin> list = List.from(coins);

  list.removeWhere((Coin coin) => coin.walletOnly);

  return list;
}

List<Coin> removeSuspended(List<Coin> coins) {
  if (!coinsBloc.isLoggedIn) return coins;
  final List<Coin> list = List.from(coins);

  list.removeWhere((Coin coin) => coin.isSuspended);

  return list;
}

Map<String, List<Coin>> removeSingleProtocol(Map<String, List<Coin>> group) {
  final Map<String, List<Coin>> copy = Map<String, List<Coin>>.from(group);
  copy.removeWhere((key, value) => value.length == 1);
  return copy;
}

CoinsByTicker removeTokensWithEmptyOrderbook(
    CoinsByTicker tokenGroups, List<OrderBookDepth> depths) {
  final CoinsByTicker copy = CoinsByTicker.from(tokenGroups);

  copy.removeWhere((key, value) {
    return value.every((coin) {
      final depth = depths.firstWhereOrNull((depth) {
        final String source = depth.source.abbr;
        final String target = depth.target.abbr;

        return (source == coin.abbr || target == coin.abbr) &&
            (abbr2Ticker(source) == abbr2Ticker(target));
      });

      return depth == null;
    });
  });

  return copy;
}

CoinsByTicker convertToCoinsByTicker(List<Coin> coinsList) {
  return coinsList.fold<CoinsByTicker>(
    {},
    (previousValue, coin) {
      final String ticker = abbr2Ticker(coin.abbr);
      final List<Coin>? coinsWithSameTicker = previousValue[ticker];

      if (coinsWithSameTicker == null) {
        previousValue[ticker] = [coin];
      } else if (!isCoinInList(coin, coinsWithSameTicker)) {
        coinsWithSameTicker.add(coin);
      }

      return previousValue;
    },
  );
}

bool isCoinInList(Coin coin, List<Coin> list) {
  return list.firstWhereOrNull((element) => element.abbr == coin.abbr) != null;
}

Iterable<Coin> filterCoinsByPhrase(Iterable<Coin> coins, String phrase) {
  if (phrase.isEmpty) return coins;
  return coins.where((Coin coin) => compareCoinByPhrase(coin, phrase));
}

bool compareCoinByPhrase(Coin coin, String phrase) {
  final String compareName = coin.name.toLowerCase();
  final String compareAbbr = abbr2Ticker(coin.abbr).toLowerCase();
  final lowerCasePhrase = phrase.toLowerCase();

  if (lowerCasePhrase.isEmpty) return false;
  return compareName.contains(lowerCasePhrase) ||
      compareAbbr.contains(lowerCasePhrase);
}

String getCoinTypeName(CoinType type) {
  switch (type) {
    case CoinType.erc20:
      return 'ERC-20';
    case CoinType.bep20:
      return 'BEP-20';
    case CoinType.qrc20:
      return 'QRC-20';
    case CoinType.utxo:
      return 'Native';
    case CoinType.smartChain:
      return 'Smart Chain';
    case CoinType.ftm20:
      return 'FTM-20';
    case CoinType.arb20:
      return 'ARB-20';
    case CoinType.etc:
      return 'ETC';
    case CoinType.avx20:
      return 'AVX-20';
    case CoinType.hrc20:
      return 'HRC-20';
    case CoinType.mvr20:
      return 'MVR-20';
    case CoinType.hco20:
      return 'HCO-20';
    case CoinType.plg20:
      return 'PLG-20';
    case CoinType.sbch:
      return 'SmartBCH';
    case CoinType.ubiq:
      return 'Ubiq';
    case CoinType.krc20:
      return 'KRC-20';
    case CoinType.cosmos:
      return 'Cosmos';
    case CoinType.iris:
      return 'Iris';
    case CoinType.slp:
      return 'SLP';
  }
}

String getCoinTypeNameLong(CoinType type) {
  switch (type) {
    case CoinType.erc20:
      return 'Ethereum (ERC-20)';
    case CoinType.bep20:
      return 'Binance (BEP-20)';
    case CoinType.qrc20:
      return 'QTUM (QRC-20)';
    case CoinType.utxo:
      return 'Native';
    case CoinType.smartChain:
      return 'Smart Chain';
    case CoinType.ftm20:
      return 'Fantom';
    case CoinType.arb20:
      return 'Arbitrum';
    case CoinType.etc:
      return 'Ethereum Classic';
    case CoinType.avx20:
      return 'Avalanche';
    case CoinType.hrc20:
      return 'Harmony (HRC-20)';
    case CoinType.mvr20:
      return 'Moonriver';
    case CoinType.hco20:
      return 'HecoChain';
    case CoinType.plg20:
      return 'Polygon';
    case CoinType.sbch:
      return 'SmartBCH';
    case CoinType.ubiq:
      return 'Ubiq';
    case CoinType.krc20:
      return 'Kucoin Chain';
    case CoinType.cosmos:
      return 'Cosmos';
    case CoinType.iris:
      return 'Iris';
    case CoinType.slp:
      return 'SLP';
  }
}

Iterable<Coin> sortByPriority(Iterable<Coin> list) {
  final sortedList = List<Coin>.from(list);
  sortedList.sort((a, b) {
    final int priorityA = a.priority;
    final int priorityB = b.priority;

    return priorityB - priorityA;
  });
  return sortedList;
}
