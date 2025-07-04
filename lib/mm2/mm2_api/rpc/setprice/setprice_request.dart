import 'package:rational/rational.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

class SetPriceRequest {
  SetPriceRequest({
    this.method = 'setprice',
    required this.base,
    required this.rel,
    required this.volume,
    required this.price,
    this.minVolume,
    this.max = false,
    this.cancelPrevious = false,
    this.userpass,
  });

  final String method;
  String? userpass;
  final String base;
  final String rel;
  final Rational volume;
  final Rational price;
  final Rational? minVolume;
  final bool max;
  final bool cancelPrevious;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'userpass': userpass,
      'base': base,
      'rel': rel,
      'volume': rat2fract(volume),
      'price': rat2fract(price),
      if (minVolume != null) 'minVolume': rat2fract(minVolume!),
      'max': max,
      'cancel_previous': cancelPrevious,
    };
  }
}
