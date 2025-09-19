part of 'nft_transactions_bloc.dart';

enum NftTxnStatus {
  loading,
  noLogin,
  success,
  failure,
}

class NftTxnState {
  final List<NftTransaction> filteredTransactions;
  final NftTransactionsFilter filters;
  final NftTxnStatus status;
  final String? errorMessage;
  NftTxnState({
    this.filteredTransactions = const [],
    this.filters = const NftTransactionsFilter(),
    this.status = NftTxnStatus.noLogin,
    this.errorMessage,
  });

  NftTxnState copyWith({
    List<NftTransaction>? filteredTransactions,
    NftTransactionsFilter? filters,
    NftTxnStatus? status,
    String? errorMessage,
  }) {
    return NftTxnState(
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      filters: filters ?? this.filters,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class NftTransactionsInitial extends NftTxnState {}
