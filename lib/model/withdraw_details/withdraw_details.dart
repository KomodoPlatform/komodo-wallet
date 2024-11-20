import 'package:web_dex/model/withdraw_details/fee_details.dart';

class WithdrawDetails {
  WithdrawDetails({
    required this.txHex,
    required this.txHash,
    required this.from,
    required this.to,
    required this.totalAmount,
    required this.spentByMe,
    required this.receivedByMe,
    required this.myBalanceChange,
    required this.blockHeight,
    required this.timestamp,
    required this.feeDetails,
    required this.coin,
    required this.internalId,
  });
  factory WithdrawDetails.fromJson(Map<String, dynamic> json) {
    final String totalAmount = json['total_amount'].toString();
    final String spentByMe = json['spent_by_me'].toString();
    final String receivedByMe = json['received_by_me'];
    final String myBalanceChange = json['my_balance_change'].toString();

    return WithdrawDetails(
      txHex: json['tx_hex'],
      txHash: json['tx_hash'],
      from: List.from(json['from']),
      to: List.from(json['to']),
      totalAmount: totalAmount,
      spentByMe: spentByMe,
      receivedByMe: receivedByMe,
      myBalanceChange: myBalanceChange,
      blockHeight: json['block_height'] ?? 0,
      timestamp: json['timestamp'],
      feeDetails: FeeDetails.fromJson(json['fee_details']),
      coin: json['coin'],
      internalId: json['internal_id'] ?? '',
    );
  }

  static WithdrawDetails empty() => WithdrawDetails(
        txHex: '',
        txHash: '',
        from: [],
        to: [],
        totalAmount: '',
        spentByMe: '',
        receivedByMe: '',
        myBalanceChange: '',
        blockHeight: 0,
        timestamp: 0,
        feeDetails: FeeDetails.empty(),
        coin: '',
        internalId: '',
      );

  final String txHex;
  final String txHash;
  final List<String> from;
  final List<String> to;
  final String totalAmount;
  final String spentByMe;
  final String receivedByMe;
  final String myBalanceChange;
  final int blockHeight;
  final int timestamp;
  final FeeDetails feeDetails;
  final String coin;
  final String internalId;

  String get toAddress {
    final List<String> toAddress = List.from(to);
    if (toAddress.length > 1) {
      toAddress.removeWhere((String toItem) => toItem == from[0]);
    }
    return toAddress.isNotEmpty ? toAddress[0] : '';
  }

  String get feeCoin => feeDetails.coin;
  String get feeValue => feeDetails.amount ?? feeDetails.totalFee ?? '0.0';

  static WithdrawDetails fromTrezorJson(Map<String, dynamic> json) {
    return WithdrawDetails(
      txHex: json['tx_hex'],
      txHash: json['tx_hash'],
      totalAmount: json['total_amount'].toString(),
      coin: json['coin'],
      myBalanceChange: json['my_balance_change'].toString(),
      receivedByMe: json['received_by_me'].toString(),
      spentByMe: json['spent_by_me'].toString(),
      internalId: json['internal_id'] ?? '',
      blockHeight: json['block_height'] ?? 0,
      timestamp: json['timestamp'],
      from: List.from(json['from']),
      to: List.from(json['to']),
      feeDetails: FeeDetails.fromJson(json['fee_details']),
    );
  }
}
