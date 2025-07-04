import 'package:rational/rational.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

class MatchRequest {
  MatchRequest({
    this.action = '',
    this.base = '',
    required this.baseAmount,
    this.destPubKey = '',
    this.method = '',
    this.rel = '',
    required this.relAmount,
    this.senderPubkey = '',
    this.uuid = '',
    this.makerOrderUuid = '',
    this.takerOrderUuid = '',
  });

  factory MatchRequest.fromJson(Map<String, dynamic> json) {
    final Rational baseAmount = fract2rat(json['base_amount_fraction']) ??
        Rational.parse(json['base_amount'] ?? '0');
    final Rational relAmount = fract2rat(json['rel_amount_fraction']) ??
        Rational.parse(json['rel_amount'] ?? '0');

    return MatchRequest(
      action: json['action'] ?? '',
      base: json['base'] ?? '',
      baseAmount: baseAmount,
      destPubKey: json['dest_pub_key'] ?? '',
      method: json['method'] ?? '',
      rel: json['rel'] ?? '',
      relAmount: relAmount,
      senderPubkey: json['sender_pubkey'] ?? '',
      uuid: json['uuid'] ?? '',
      makerOrderUuid: json['maker_order_uuid'] ?? '',
      takerOrderUuid: json['taker_order_uuid'] ?? '',
    );
  }

  String action;
  String base;
  Rational baseAmount;
  String destPubKey;
  String method;
  String rel;
  Rational relAmount;
  String senderPubkey;
  String uuid;
  String makerOrderUuid;
  String takerOrderUuid;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'action': action,
        'base': base,
        'base_amount': baseAmount.toDouble().toString(),
        'base_amount_fraction': rat2fract(baseAmount),
        'dest_pub_key': destPubKey,
        'method': method,
        'rel': rel,
        'rel_amount': relAmount.toDouble().toString(),
        'rel_amount_fraction': rat2fract(relAmount),
        'sender_pubkey': senderPubkey,
        'uuid': uuid,
        'maker_order_uuid': makerOrderUuid,
        'taker_order_uuid': takerOrderUuid,
      };
}
