import 'package:rational/rational.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

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

  factory MatchRequest.fromJson(JsonMap json) {
    final Rational baseAmount =
        fract2rat(json.valueOrNull<JsonMap>('base_amount_fraction')) ??
        Rational.parse(json.valueOrNull<String>('base_amount') ?? '0');
    final Rational relAmount =
        fract2rat(json.valueOrNull<JsonMap>('rel_amount_fraction')) ??
        Rational.parse(json.valueOrNull<String>('rel_amount') ?? '0');

    return MatchRequest(
      action: json.valueOrNull<String>('action') ?? '',
      base: json.valueOrNull<String>('base') ?? '',
      baseAmount: baseAmount,
      destPubKey: json.valueOrNull<String>('dest_pub_key') ?? '',
      method: json.valueOrNull<String>('method') ?? '',
      rel: json.valueOrNull<String>('rel') ?? '',
      relAmount: relAmount,
      senderPubkey: json.valueOrNull<String>('sender_pubkey') ?? '',
      uuid: json.valueOrNull<String>('uuid') ?? '',
      makerOrderUuid: json.valueOrNull<String>('maker_order_uuid') ?? '',
      takerOrderUuid: json.valueOrNull<String>('taker_order_uuid') ?? '',
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

  JsonMap toJson() => <String, dynamic>{
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
