import 'package:intl/intl.dart';
import 'package:komodo_wallet/model/withdraw_details/fee_details.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

class Transaction {
  Transaction({
    required this.blockHeight,
    required this.coin,
    required this.confirmations,
    required this.feeDetails,
    required this.from,
    required this.internalId,
    required this.myBalanceChange,
    required this.receivedByMe,
    required this.spentByMe,
    required this.timestamp,
    required this.to,
    required this.totalAmount,
    required this.txHash,
    required this.txHex,
    required this.memo,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      blockHeight: assertInt(json['block_height']) ?? 0,
      coin: _parseCoin(json['coin']) ?? '',
      confirmations: json['confirmations'] ?? 0,
      feeDetails: FeeDetails.fromJson(json['fee_details']),
      from: json['from'] != null
          ? List<String>.from(json['from'].map<dynamic>((dynamic x) => x))
          : <String>[],
      internalId: json['internal_id'] ?? '',
      myBalanceChange: assertString(json['my_balance_change']) ?? '0.0',
      receivedByMe: assertString(json['received_by_me']) ?? '0.0',
      spentByMe: assertString(json['spent_by_me']) ?? '0.0',
      timestamp: json['timestamp'] ?? 0,
      to: json['to'] != null
          ? List<String>.from(json['to'].map<dynamic>((dynamic x) => x))
          : <String>[],
      totalAmount: assertString(json['total_amount']) ?? '',
      txHash: json['tx_hash'] ?? '',
      txHex: json['tx_hex'] ?? '',
      memo: json['memo'],
    );
  }

  String coin;
  final int blockHeight;
  final int confirmations;
  final FeeDetails feeDetails;
  final List<String> from;
  final String internalId;
  final String myBalanceChange;
  final String receivedByMe;
  final String spentByMe;
  final int timestamp;
  final List<String> to;
  final String totalAmount;
  final String txHash;
  final String txHex;
  final String? memo;

  String get formattedTime {
    if (timestamp == 0 && confirmations == 0) {
      return 'unconfirmed';
    } else if (timestamp == 0 && confirmations > 0) {
      return 'confirmed';
    } else {
      return DateFormat('dd MMM yyyy HH:mm')
          .format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
    }
  }

  /// Timestamp as a [DateTime] object.
  DateTime get timestampDate =>
      DateTime.fromMillisecondsSinceEpoch(timestampMilliseconds);

  /// Timestamp in milliseconds since epoch (UTC).
  /// Unix timestamp, but in milliseconds since epoch.
  int get timestampMilliseconds => timestamp * 1000;

  String get toAddress {
    final List<String> toAddress = List.from(to);
    if (toAddress.length > 1) {
      toAddress.removeWhere((String toItem) => toItem == from[0]);
    }
    return toAddress.isNotEmpty ? toAddress[0] : '';
  }

  bool get isReceived => double.parse(myBalanceChange) > 0;

  Transaction copyWith({
    int? blockHeight,
    String? coin,
    int? confirmations,
    FeeDetails? feeDetails,
    List<String>? from,
    String? internalId,
    String? myBalanceChange,
    String? receivedByMe,
    String? spentByMe,
    int? timestamp,
    List<String>? to,
    String? totalAmount,
    String? txHash,
    String? txHex,
    String? memo,
  }) {
    return Transaction(
      blockHeight: blockHeight ?? this.blockHeight,
      coin: coin ?? this.coin,
      confirmations: confirmations ?? this.confirmations,
      feeDetails: feeDetails ?? this.feeDetails,
      from: from ?? this.from,
      internalId: internalId ?? this.internalId,
      myBalanceChange: myBalanceChange ?? this.myBalanceChange,
      receivedByMe: receivedByMe ?? this.receivedByMe,
      spentByMe: spentByMe ?? this.spentByMe,
      timestamp: timestamp ?? this.timestamp,
      to: to ?? this.to,
      totalAmount: totalAmount ?? this.totalAmount,
      txHash: txHash ?? this.txHash,
      txHex: txHex ?? this.txHex,
      memo: memo ?? this.memo,
    );
  }
}

String? _parseCoin(String value) {
  if (value ==
      'IBC/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2') {
    return 'ATOM-IBC_IRIS';
  } else {
    return value;
  }
}
