import 'package:rational/rational.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

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

  factory Orderbook.fromJson(JsonMap json) {
    return Orderbook(
      base: json.valueOrNull<String>('base') ?? '',
      rel: json.valueOrNull<String>('rel') ?? '',
      asks: json
          .value<List<JsonMap>>('asks')
          .map<Order>(
            (JsonMap item) => Order.fromJson(
              item,
              direction: OrderDirection.ask,
              otherCoin: json.valueOrNull<String>('rel') ?? '',
            ),
          )
          .toList(),
      bids: json
          .value<List<JsonMap>>('bids')
          .map<Order>(
            (JsonMap item) => Order.fromJson(
              item,
              direction: OrderDirection.bid,
              otherCoin: json.valueOrNull<String>('base') ?? '',
            ),
          )
          .toList(),
      bidsBaseVolTotal:
          fract2rat(
            json.valueOrNull<JsonMap>('total_bids_base_vol_fraction'),
          ) ??
          Rational.parse(
            json.valueOrNull<String>('total_bids_base_vol') ?? '0',
          ),
      bidsRelVolTotal:
          fract2rat(json.valueOrNull<JsonMap>('total_bids_rel_vol_fraction')) ??
          Rational.parse(json.valueOrNull<String>('total_bids_rel_vol') ?? '0'),
      asksBaseVolTotal:
          fract2rat(
            json.valueOrNull<JsonMap>('total_asks_base_vol_fraction'),
          ) ??
          Rational.parse(
            json.valueOrNull<String>('total_asks_base_vol') ?? '0',
          ),
      asksRelVolTotal:
          fract2rat(json.valueOrNull<JsonMap>('total_asks_rel_vol_fraction')) ??
          Rational.parse(json.valueOrNull<String>('total_asks_rel_vol') ?? '0'),
      timestamp: json.value<int>('timestamp'),
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
