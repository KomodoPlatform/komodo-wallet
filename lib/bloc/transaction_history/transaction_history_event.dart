import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

abstract class TransactionHistoryEvent {
  const TransactionHistoryEvent();
}

class TransactionHistorySubscribe extends TransactionHistoryEvent {
  const TransactionHistorySubscribe({required this.coin});
  final Coin coin;
}

class TransactionHistoryUpdated extends TransactionHistoryEvent {
  const TransactionHistoryUpdated({required this.transactions});
  final List<Transaction>? transactions;
}

class TransactionHistoryStartedLoading extends TransactionHistoryEvent {
  const TransactionHistoryStartedLoading();
}

class TransactionHistoryFailure extends TransactionHistoryEvent {
  TransactionHistoryFailure({required this.error});
  final BaseError error;
}
