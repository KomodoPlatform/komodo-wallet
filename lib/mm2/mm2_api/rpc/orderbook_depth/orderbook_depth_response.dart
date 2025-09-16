import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/model/coin.dart';

class OrderBookDepthResponse {
  OrderBookDepthResponse(this.list);

  factory OrderBookDepthResponse.fromJson(
    Map<String, dynamic> json,
    CoinsRepo coinsRepository,
  ) {
    final List<OrderBookDepth> list = [];
    final List result = json['result'];

    for (int i = 0; i < result.length; i++) {
      final Map<String, dynamic> item = result[i];
      final pair = OrderBookDepth.fromJson(item, coinsRepository);
      if (pair != null) list.add(pair);
    }
    list.sort((a, b) => a.source.abbr.compareTo(b.source.abbr));
    return OrderBookDepthResponse(list);
  }

  List<OrderBookDepth> list;
}

class OrderBookDepth {
  OrderBookDepth(this.source, this.target, this.asks, this.bids);

  Coin source;
  Coin target;
  int asks;
  int bids;

  static OrderBookDepth? fromJson(
    Map<String, dynamic> map,
    CoinsRepo coinsRepository,
  ) {
    final List<dynamic> pair = map['pair'];
    final Map depth = map['depth'];

    final String sourceName = (pair[0] ?? '').replaceAll('"', '');
    final String targetName = (pair[1] ?? '').replaceAll('"', '');

    final Coin? source = coinsRepository.getCoin(sourceName);
    final Coin? target = coinsRepository.getCoin(targetName);

    if (source == null || target == null) return null;

    return OrderBookDepth(
        source, target, depth['asks'] ?? 0, depth['bids'] ?? 0);
  }

  @override
  String toString() {
    return 'OrderBookDepth($source, $target, $asks, $bids)';
  }
}
