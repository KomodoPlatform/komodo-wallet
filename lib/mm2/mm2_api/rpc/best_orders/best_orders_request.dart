import 'package:rational/rational.dart';

class BestOrdersRequest {
  BestOrdersRequest({
    this.method = 'best_orders',
    required this.coin,
    required this.action,
    this.type = BestOrdersRequestType.volume,
    this.volume,
    this.number,
  }) : assert(
         (type == BestOrdersRequestType.number && number != null) ||
             (type == BestOrdersRequestType.volume && volume != null),
       );

  late String userpass;
  final String method;
  final String coin;
  final String action;
  final BestOrdersRequestType type;
  final Rational? volume;
  final int? number;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'method': method,
    'userpass': userpass,
    'mmrpc': '2.0',
    'params': <String, dynamic>{
      'coin': coin,
      'action': 'sell',
      'request_by': <String, dynamic>{'type': _typeJson, 'value': _valueJson},
    },
  };

  dynamic get _valueJson {
    switch (type) {
      case BestOrdersRequestType.number:
        // ignore: unnecessary_this
        final int? number = this.number;
        if (number == null) return null;

        return number;
      case BestOrdersRequestType.volume:
        final Rational? volume = this.volume;
        if (volume == null) return null;

        return {
          'numer': volume.numerator.toString(),
          'denom': volume.denominator.toString(),
        };
    }
  }

  String get _typeJson {
    switch (type) {
      case BestOrdersRequestType.number:
        return 'number';
      case BestOrdersRequestType.volume:
        return 'volume';
    }
  }
}

enum BestOrdersRequestType { volume, number }
