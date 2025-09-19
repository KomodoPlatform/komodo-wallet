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
      maxVolume: fract2rat(json['base_max_volume_fraction']) ??
          Rational.parse(json['base_max_volume']),
      minVolume: fract2rat(json['base_min_volume_fraction']) ??
          Rational.parse(json['base_min_volume']),
      minVolumeRel: fract2rat(json['rel_min_volume_fraction']) ??
          Rational.parse(json['rel_min_volume']),
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
}

enum OrderDirection { bid, ask }

// This const is used to identify and highlight newly created
// order preview in maker form orderbook (instead of isTarget flag)
final String orderPreviewUuid = const Uuid().v1();
