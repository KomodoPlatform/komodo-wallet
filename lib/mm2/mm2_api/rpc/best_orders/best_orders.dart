import 'package:rational/rational.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/shared/utils/utils.dart';

class BestOrders {
  BestOrders({this.result, this.error});

  factory BestOrders.fromJson(Map<String, dynamic> json) {
    final Map<String, List<BestOrder>> ordersMap = <String, List<BestOrder>>{};
    for (var key in json['result']['orders'].keys) {
      final List<BestOrder> bestOrders = [];
      for (var result in json['result']['orders'][key]) {
        bestOrders.add(BestOrder.fromJson(result));
      }
      ordersMap.putIfAbsent(key, () => bestOrders);
    }
    return BestOrders(result: ordersMap);
  }

  Map<String, List<BestOrder>>? result;
  BaseError? error;
}

class BestOrder {
  const BestOrder({
    required this.price,
    required this.maxVolume,
    required this.minVolume,
    required this.coin,
    required this.address,
    required this.uuid,
  });

  factory BestOrder.fromOrder(Order order, String? coin) {
    return BestOrder(
      price: order.price,
      maxVolume: order.maxVolume,
      minVolume: order.minVolume ?? Rational.zero,
      coin: coin ?? order.base,
      address: order.address?.addressData ?? '',
      uuid: order.uuid ?? '',
    );
  }

  factory BestOrder.fromJson(Map<String, dynamic> json) {
    return BestOrder(
      price: fract2rat(json['price']['fraction']) ??
          Rational.parse(json['price']['decimal']),
      maxVolume: fract2rat(json['base_max_volume']['fraction']) ??
          Rational.parse(json['base_max_volume']['decimal']),
      minVolume: fract2rat(json['base_min_volume']['fraction']) ??
          Rational.parse(json['base_min_volume']['decimal']),
      coin: json['coin'],
      address: json['address']['address_data'],
      uuid: json['uuid'],
    );
  }

  final Rational price;
  final Rational maxVolume;
  final Rational minVolume;
  final String coin;
  final String address;

  @override
  String toString() {
    return 'BestOrder($coin, $price)';
  }

  final String uuid;
}
