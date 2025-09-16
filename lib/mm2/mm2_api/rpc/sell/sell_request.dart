import 'package:rational/rational.dart';

class SellRequest {
  SellRequest({
    this.method = 'sell',
    required this.base,
    required this.rel,
    required this.volume,
    required this.price,
    required this.orderType,
  });

  factory SellRequest.fromJson(Map<String, dynamic> json) {
    final String typeStr =
        json['order_type'] != null && json['order_type']['type'] != null
            ? json['order_type']['type']
            : null;

    SellBuyOrderType orderType;
    switch (typeStr) {
      case 'FillOrKill':
        orderType = SellBuyOrderType.fillOrKill;
        break;
      default:
        orderType = SellBuyOrderType.goodTillCancelled;
    }

    return SellRequest(
      method: json['method'],
      base: json['base'],
      rel: json['rel'],
      volume: json['volume'],
      price: json['price'],
      orderType: orderType,
    );
  }

  late String userpass;
  final String method;
  final String base;
  final String rel;
  final SellBuyOrderType orderType;
  bool? baseNota;
  int? baseConfs;
  bool? relNota;
  int? relConfs;
  final Rational price;
  final Rational volume;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userpass': userpass,
        'method': method,
        'base': base,
        'rel': rel,
        'volume': {
          'numer': volume.numerator.toString(),
          'denom': volume.denominator.toString()
        },
        'price': {
          'numer': price.numerator.toString(),
          'denom': price.denominator.toString()
        },
        'order_type': {
          'type': orderType == SellBuyOrderType.fillOrKill
              ? 'FillOrKill'
              : 'GoodTillCancelled'
        },
      };
}

enum SellBuyOrderType { goodTillCancelled, fillOrKill }
