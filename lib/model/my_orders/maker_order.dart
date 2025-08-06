import 'package:rational/rational.dart';
import 'package:web_dex/model/my_orders/matches.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

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

  factory MakerOrder.fromJson(JsonMap json) {
    final Rational maxBaseVol =
        fract2rat(json.valueOrNull<JsonMap>('max_base_vol_fraction')) ??
        Rational.parse(json.valueOrNull<String>('max_base_vol') ?? '0');
    final Rational price =
        fract2rat(json.valueOrNull<JsonMap>('price_fraction')) ??
        Rational.parse(json.valueOrNull<String>('price') ?? '0');
    final Rational availableAmount =
        fract2rat(json.valueOrNull<JsonMap>('available_amount_fraction')) ??
        Rational.parse(json.valueOrNull<String>('available_amount') ?? '0');

    return MakerOrder(
      base: json.valueOrNull<String>('base') ?? '',
      createdAt: json.value<int>('created_at'),
      availableAmount: availableAmount,
      cancellable: json.value<bool>('cancellable'),
      matches: json
          .value<JsonMap>('matches')
          .map(
            (dynamic k, dynamic v) => MapEntry<String, Matches>(
              k.toString(),
              Matches.fromJson(v as JsonMap),
            ),
          ),
      maxBaseVol: maxBaseVol,
      minBaseVol: json.valueOrNull<String>('min_base_vol') ?? '',
      price: price,
      rel: json.valueOrNull<String>('rel') ?? '',
      startedSwaps: json.value<List<String>>('started_swaps'),
      uuid: json.valueOrNull<String>('uuid') ?? '',
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

  JsonMap toJson() => <String, dynamic>{
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
