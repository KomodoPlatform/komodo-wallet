import 'package:rational/rational.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class TradePreimageRequest implements BaseRequest {
  TradePreimageRequest({
    required this.base,
    required this.rel,
    required this.swapMethod,
    required this.price,
    this.volume,
    this.max = false,
  }) {
    if (volume == null) {
      assert(max == true && swapMethod == 'setprice');
    }
    if (max == true) {
      assert(swapMethod == 'setprice');
    }
  }

  final String mmrpc = '2.0';
  final String base;
  final String rel;
  final String swapMethod; // 'buy', 'sell' or 'setprice'
  final Rational price;
  final Rational? volume;
  final bool max;

  @override
  final String method = 'trade_preimage';
  @override
  late String userpass;

  @override
  Map<String, dynamic> toJson() {
    final Rational? volume = this.volume;

    final Map<String, dynamic> json = <String, dynamic>{
      'userpass': userpass,
      'method': method,
      'mmrpc': mmrpc,
      'params': {
        'base': base,
        'rel': rel,
        'swap_method': swapMethod,
        if (volume != null)
          'volume': {
            'numer': volume.numerator.toString(),
            'denom': volume.denominator.toString(),
          },
        'price': {
          'numer': price.numerator.toString(),
          'denom': price.denominator.toString(),
        },
        'max': max,
      },
    };

    return json;
  }
}
