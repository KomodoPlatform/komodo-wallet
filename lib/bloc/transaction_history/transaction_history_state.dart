import 'package:equatable/equatable.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:komodo_defi_types/types.dart';

final class TransactionHistoryState extends Equatable {
  const TransactionHistoryState({
    required this.transactions,
    required this.loading,
    required this.error,
  });

  final List<Transaction> transactions;
  final bool loading;
  final BaseError? error;

  @override
  List<Object?> get props => [transactions, loading];

  const TransactionHistoryState.initial()
      : transactions = const [],
        loading = false,
        error = null;

  TransactionHistoryState copyWith({
    List<Transaction>? transactions,
    bool? loading,
    BaseError? error,
  }) {
    return TransactionHistoryState(
      transactions: transactions ?? this.transactions,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}
