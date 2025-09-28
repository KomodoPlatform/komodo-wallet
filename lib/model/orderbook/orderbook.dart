import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart' as sdk;
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

  factory Orderbook.fromSdkResponse(sdk.OrderbookResponse response) {
    List<Order> _mapOrders(
      List<sdk.OrderInfo> orders,
      OrderDirection direction,
    ) {
      return orders
          .map(
            (info) => Order.fromOrderInfo(
              info,
              base: response.base,
              rel: response.rel,
              direction: direction,
            ),
          )
          .toList();
    }

    final asks = _mapOrders(response.asks, OrderDirection.ask);
    final bids = _mapOrders(response.bids, OrderDirection.bid);

    Rational _totalBaseVolume(List<Order> orders) {
      return orders.fold<Rational>(
        Rational.zero,
        (sum, order) => sum + order.maxVolume,
      );
    }

    Rational _totalRelVolume(List<Order> orders) {
      return orders.fold<Rational>(
        Rational.zero,
        (sum, order) => sum + (order.maxVolume * order.price),
      );
    }

    return Orderbook(
      base: response.base,
      rel: response.rel,
      bidsBaseVolTotal: _totalBaseVolume(bids),
      bidsRelVolTotal: _totalRelVolume(bids),
      asksBaseVolTotal: _totalBaseVolume(asks),
      asksRelVolTotal: _totalRelVolume(asks),
      bids: bids,
      asks: asks,
      timestamp: response.timestamp,
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
