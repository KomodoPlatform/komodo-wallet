import 'package:rational/rational.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/shared/utils/utils.dart';

class Orderbook {
  Orderbook({
    required this.base,
    required this.rel,
    required this.bidsBaseVolTotal,
    required this.bidsRelVolTotal,
    required this.asksBaseVolTotal,
    required this.asksRelVolTotal,
    required this.bids,
    required this.asks,
    required this.timestamp,
  });

  factory Orderbook.fromJson(Map<String, dynamic> json) {
    return Orderbook(
      base: json['base'],
      rel: json['rel'],
      asks: json['asks']
          .map<Order>(
            (dynamic item) => Order.fromJson(
              item,
              direction: OrderDirection.ask,
              otherCoin: json['rel'],
            ),
          )
          .toList(),
      bids: json['bids']
          .map<Order>(
            (dynamic item) => Order.fromJson(
              item,
              direction: OrderDirection.bid,
              otherCoin: json['base'],
            ),
          )
          .toList(),
      bidsBaseVolTotal:
          fract2rat(json['total_bids_base_vol_fraction']) ??
          Rational.parse(json['total_bids_base_vol']),
      bidsRelVolTotal:
          fract2rat(json['total_bids_rel_vol_fraction']) ??
          Rational.parse(json['total_bids_rel_vol']),
      asksBaseVolTotal:
          fract2rat(json['total_asks_base_vol_fraction']) ??
          Rational.parse(json['total_asks_base_vol']),
      asksRelVolTotal:
          fract2rat(json['total_asks_rel_vol_fraction']) ??
          Rational.parse(json['total_asks_rel_vol']),
      timestamp: json['timestamp'],
    );
  }

  final String base;
  final String rel;
  final List<Order> bids;
  final List<Order> asks;
  final Rational bidsBaseVolTotal;
  final Rational bidsRelVolTotal;
  final Rational asksBaseVolTotal;
  final Rational asksRelVolTotal;
  final int timestamp;
}
