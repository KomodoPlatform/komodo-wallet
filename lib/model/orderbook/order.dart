import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart'
    show NumericValue, OrderInfo;
import 'package:rational/rational.dart';
import 'package:uuid/uuid.dart';
import 'package:web_dex/shared/utils/utils.dart';

class Order {
  Order({
    required this.base,
    required this.rel,
    required this.direction,
    required this.price,
    required this.maxVolume,
    this.address,
    this.uuid,
    this.pubkey,
    this.minVolume,
    this.minVolumeRel,
  });

  factory Order.fromJson(
    Map<String, dynamic> json, {
    required OrderDirection direction,
    required String otherCoin,
  }) {
    return Order(
      base: json['coin'],
      rel: otherCoin,
      direction: direction,
      address: json['address'],
      uuid: json['uuid'],
      pubkey: json['pubkey'],
      price: fract2rat(json['price_fraction']) ?? Rational.parse(json['price']),
      maxVolume:
          fract2rat(json['base_max_volume_fraction']) ??
          Rational.parse(json['base_max_volume']),
      minVolume:
          fract2rat(json['base_min_volume_fraction']) ??
          Rational.parse(json['base_min_volume']),
      minVolumeRel:
          fract2rat(json['rel_min_volume_fraction']) ??
          Rational.parse(json['rel_min_volume']),
    );
  }

  factory Order.fromOrderInfo(
    OrderInfo info, {
    required String base,
    required String rel,
    required OrderDirection direction,
  }) {
    final Rational? price = _numericValueToRational(info.price);

    final Rational? maxVolume = _numericValueToRational(
      info.baseMaxVolume ?? info.baseMaxVolumeAggregated,
    );

    if (price == null || maxVolume == null) {
      throw ArgumentError('Invalid price or maxVolume in OrderInfo');
    }

    final Rational? minVolume = _numericValueToRational(
      info.baseMinVolume,
    );

    final Rational? minVolumeRel =
        _numericValueToRational(info.relMinVolume) ??
        (minVolume != null ? minVolume * price : null);

    return Order(
      base: base,
      rel: rel,
      direction: direction,
      price: price,
      maxVolume: maxVolume,
      address: info.address?.addressData,
      uuid: info.uuid,
      pubkey: info.pubkey,
      minVolume: minVolume,
      minVolumeRel: minVolumeRel,
    );
  }

  final String base;
  final String rel;
  final OrderDirection direction;
  final Rational maxVolume;
  final Rational price;
  final String? address;
  final String? uuid;
  final String? pubkey;
  final Rational? minVolume;
  final Rational? minVolumeRel;

  bool get isBid => direction == OrderDirection.bid;
  bool get isAsk => direction == OrderDirection.ask;

  static Rational? _numericValueToRational(NumericValue? value) {
    if (value == null) return null;
    if (value.rational != null) {
      return value.rational;
    }
    final fraction = value.fraction;
    if (fraction != null) {
      final fractionRat = fract2rat(fraction.toJson(), false);
      if (fractionRat != null) {
        return fractionRat;
      }
    }
    final decimal = value.decimal.trim();
    if (decimal.isEmpty) {
      return null;
    }
    try {
      return Rational.parse(decimal);
    } catch (_) {
      return null;
    }
  }
}

enum OrderDirection { bid, ask }

// This const is used to identify and highlight newly created
// order preview in maker form orderbook (instead of isTarget flag)
final String orderPreviewUuid = const Uuid().v1();
