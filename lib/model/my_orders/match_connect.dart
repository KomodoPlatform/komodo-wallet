class MatchConnect {
  MatchConnect({
    required this.destPubKey,
    required this.makerOrderUuid,
    required this.method,
    required this.senderPubkey,
    required this.takerOrderUuid,
  });

  factory MatchConnect.fromJson(Map<String, dynamic> json) => MatchConnect(
        destPubKey: json['dest_pub_key'] ?? '',
        makerOrderUuid: json['maker_order_uuid'] ?? '',
        method: json['method'] ?? '',
        senderPubkey: json['sender_pubkey'] ?? '',
        takerOrderUuid: json['taker_order_uuid'] ?? '',
      );

  String destPubKey;
  String makerOrderUuid;
  String method;
  String senderPubkey;
  String takerOrderUuid;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dest_pub_key': destPubKey,
        'maker_order_uuid': makerOrderUuid,
        'method': method,
        'sender_pubkey': senderPubkey,
        'taker_order_uuid': takerOrderUuid,
      };
}
