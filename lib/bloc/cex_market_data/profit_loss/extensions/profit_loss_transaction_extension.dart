import 'package:komodo_defi_types/komodo_defi_types.dart';

extension ProfitLossTransactionExtension on Transaction {
  /// The total amount of the coin transferred in the transaction as a double.
  /// This is the absolute value of the [totalAmount].
  double get totalAmountAsDouble => balanceChanges.totalAmount.toDouble().abs();

  /// The amount of the coin received in the transaction as a double.
  /// This is the [receivedByMe] as a double.
  double get amountReceived => balanceChanges.receivedByMe.toDouble();

  /// The amount of the coin spent in the transaction as a double.
  /// This is the [spentByMe] as a double.
  double get amountSpent => balanceChanges.spentByMe.toDouble();

  /// The net change in the coin balance as a double.
  /// This is the [myBalanceChange] as a double.
  double get balanceChange => amount.toDouble();

  /// The timestamp of the transaction as a [DateTime] at midnight.
  DateTime get timeStampMidnight =>
      DateTime(timestamp.year, timestamp.month, timestamp.day);

  /// Returns true if the transaction is a deposit. I.e. the user receives the
  /// coin and does not spend any of it. This is true if the transaction is
  /// on the receiving end of a transaction, as the sender pays transaction fees
  /// for UTXO coins and the receiver does not.
  bool get isDeposit =>
      amountReceived > 0 && amountSpent == 0 && balanceChange > 0;
}
