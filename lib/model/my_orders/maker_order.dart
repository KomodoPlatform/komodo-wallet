import 'package:rational/rational.dart';
import 'package:web_dex/model/my_orders/matches.dart';
import 'package:web_dex/shared/utils/utils.dart';

class MakerOrder {
  MakerOrder({
    required this.base,
    required this.createdAt,
    required this.availableAmount,
    required this.cancellable,
    required this.matches,
    required this.maxBaseVol,
    required this.minBaseVol,
    required this.price,
    required this.rel,
    required this.startedSwaps,
    required this.uuid,
  });

  factory MakerOrder.fromJson(Map<String, dynamic> json) {
    final Rational maxBaseVol =
        fract2rat(json['max_base_vol_fraction']) ??
        Rational.parse(json['max_base_vol'] ?? '0');
    final Rational price =
        fract2rat(json['price_fraction']) ??
        Rational.parse(json['price'] ?? '0');
    final Rational availableAmount =
        fract2rat(json['available_amount_fraction']) ??
        Rational.parse(json['available_amount'] ?? '0');

    return MakerOrder(
      base: json['base'] ?? '',
      createdAt: json['created_at'] ?? 0,
      availableAmount: availableAmount,
      cancellable: json['cancellable'] ?? false,
      matches: Map<String, dynamic>.from(json['matches'] ?? <String, dynamic>{})
          .map(
            (dynamic k, dynamic v) =>
                MapEntry<String, Matches>(k, Matches.fromJson(v)),
          ),
      maxBaseVol: maxBaseVol,
      minBaseVol: json['min_base_vol'] ?? '',
      price: price,
      rel: json['rel'] ?? '',
      startedSwaps: List<String>.from(
        (json['started_swaps'] ?? <String>[]).map<dynamic>((dynamic x) => x),
      ),
      uuid: json['uuid'] ?? '',
    );
  }

  String base;
  int createdAt;
  Rational availableAmount;
  bool cancellable;
  Map<String, Matches> matches;
  Rational maxBaseVol;
  String minBaseVol;
  Rational price;
  String rel;
  List<String> startedSwaps;
  String uuid;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'base': base,
    'created_at': createdAt,
    'available_amount': availableAmount.toDouble().toString(),
    'available_amount_fraction': rat2fract(availableAmount),
    'cancellable': cancellable,
    'matches': Map<dynamic, dynamic>.from(matches).map<dynamic, dynamic>(
      (dynamic k, dynamic v) => MapEntry<String, dynamic>(k, v.toJson()),
    ),
    'max_base_vol': maxBaseVol.toDouble().toString(),
    'max_base_vol_fraction': rat2fract(maxBaseVol),
    'min_base_vol': minBaseVol,
    'price': price.toDouble().toString(),
    'price_fraction': rat2fract(price),
    'rel': rel,
    'started_swaps': List<dynamic>.from(
      startedSwaps.map<dynamic>((dynamic x) => x),
    ),
    'uuid': uuid,
  };
}
