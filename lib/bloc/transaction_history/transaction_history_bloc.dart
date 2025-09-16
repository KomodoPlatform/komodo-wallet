import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_event.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/extensions/transaction_extensions.dart';
import 'package:web_dex/shared/utils/utils.dart';

class TransactionHistoryBloc
    extends Bloc<TransactionHistoryEvent, TransactionHistoryState> {
  TransactionHistoryBloc({
    required KomodoDefiSdk sdk,
  })  : _sdk = sdk,
        super(const TransactionHistoryState.initial()) {
    on<TransactionHistorySubscribe>(_onSubscribe, transformer: restartable());
    on<TransactionHistoryStartedLoading>(_onStartedLoading);
    on<TransactionHistoryUpdated>(_onUpdated);
    on<TransactionHistoryFailure>(_onFailure);
  }

  final KomodoDefiSdk _sdk;
  StreamSubscription<List<Transaction>>? _historySubscription;
  StreamSubscription<Transaction>? _newTransactionsSubscription;

  // TODO: Remove or move to SDK
  final Set<String> _processedTxIds = {};

  @override
  Future<void> close() async {
    await _historySubscription?.cancel();
    await _newTransactionsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onSubscribe(
    TransactionHistorySubscribe event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    emit(const TransactionHistoryState.initial());

    if (!hasTxHistorySupport(event.coin)) {
      emit(
        state.copyWith(
          loading: false,
          error: TextError(
            error: 'Transaction history is not supported for this coin.',
          ),
          transactions: const [],
        ),
      );
      return;
    }

    try {
      await _historySubscription?.cancel();
      await _newTransactionsSubscription?.cancel();
      _processedTxIds.clear();

      add(const TransactionHistoryStartedLoading());
      final asset = _sdk.assets.available[event.coin.id];
      if (asset == null) {
        throw Exception('Asset ${event.coin.id} not found in known coins list');
      }

      final pubkeys = await _sdk.pubkeys.getPubkeys(asset);
      final myAddresses = pubkeys.keys.map((p) => p.address).toSet();

      // Subscribe to historical transactions
      _historySubscription =
          _sdk.transactions.getTransactionsStreamed(asset).listen(
        (newTransactions) {
          // Filter out any transactions we've already processed
          final uniqueTransactions = newTransactions.where((tx) {
            final isNew = !_processedTxIds.contains(tx.internalId);
            if (isNew) {
              _processedTxIds.add(tx.internalId);
            }
            return isNew;
          }).toList();

          if (uniqueTransactions.isEmpty) return;

          final sanitized =
              uniqueTransactions.map((tx) => tx.sanitize(myAddresses)).toList();
          final updatedTransactions = List<Transaction>.of(state.transactions)
            ..addAll(sanitized)
            ..sort(_sortTransactions);

          if (event.coin.isErcType) {
            _flagTransactions(updatedTransactions, event.coin);
          }

          add(TransactionHistoryUpdated(transactions: updatedTransactions));
        },
        onError: (error) {
          add(
            TransactionHistoryFailure(
              error: TextError(error: LocaleKeys.somethingWrong.tr()),
            ),
          );
        },
        onDone: () {
          if (state.error == null && state.loading) {
            add(TransactionHistoryUpdated(transactions: state.transactions));
          }
          // Once historical load is complete, start watching for new transactions
          _subscribeToNewTransactions(asset, event.coin, myAddresses);
        },
      );
    } catch (e, s) {
      log(
        'Error loading transaction history: $e',
        isError: true,
        path: 'transaction_history_bloc->_onSubscribe',
        trace: s,
      );
      add(
        TransactionHistoryFailure(
          error: TextError(error: LocaleKeys.somethingWrong.tr()),
        ),
      );
    }
  }

  void _subscribeToNewTransactions(
      Asset asset, Coin coin, Set<String> myAddresses) {
    _newTransactionsSubscription =
        _sdk.transactions.watchTransactions(asset).listen(
      (newTransaction) {
        if (_processedTxIds.contains(newTransaction.internalId)) return;

        _processedTxIds.add(newTransaction.internalId);

        final sanitized = newTransaction.sanitize(myAddresses);
        final updatedTransactions = List<Transaction>.of(state.transactions)
          ..add(sanitized)
          ..sort(_sortTransactions);

        if (coin.isErcType) {
          _flagTransactions(updatedTransactions, coin);
        }

        add(TransactionHistoryUpdated(transactions: updatedTransactions));
      },
      onError: (error) {
        add(
          TransactionHistoryFailure(
            error: TextError(error: LocaleKeys.somethingWrong.tr()),
          ),
        );
      },
    );
  }

  void _onUpdated(
    TransactionHistoryUpdated event,
    Emitter<TransactionHistoryState> emit,
  ) {
    emit(
      state.copyWith(
        transactions: event.transactions,
        loading: false,
      ),
    );
  }

  void _onStartedLoading(
    TransactionHistoryStartedLoading event,
    Emitter<TransactionHistoryState> emit,
  ) {
    emit(state.copyWith(loading: true));
  }

  void _onFailure(
    TransactionHistoryFailure event,
    Emitter<TransactionHistoryState> emit,
  ) {
    emit(
      state.copyWith(
        loading: false,
        error: event.error,
      ),
    );
  }
}

int _sortTransactions(Transaction tx1, Transaction tx2) {
  if (tx2.timestamp == DateTime.now()) {
    return 1;
  } else if (tx1.timestamp == DateTime.now()) {
    return -1;
  }
  return tx2.timestamp.compareTo(tx1.timestamp);
}

void _flagTransactions(List<Transaction> transactions, Coin coin) {
  if (!coin.isErcType) return;
  transactions
      .removeWhere((tx) => tx.balanceChanges.totalAmount.toDouble() == 0.0);
}

class Pagination {
  Pagination({
    this.fromId,
    this.pageNumber,
  });
  final String? fromId;
  final int? pageNumber;

  Map<String, dynamic> toJson() => {
        if (fromId != null) 'FromId': fromId,
        if (pageNumber != null) 'PageNumber': pageNumber,
      };
}

/// Represents different ways to paginate transaction history
sealed class TransactionPagination {
  const TransactionPagination();

  /// Get the limit of transactions to return, if applicable
  int? get limit;
}

/// Standard page-based pagination
class PagePagination extends TransactionPagination {
  const PagePagination({
    required this.pageNumber,
    required this.itemsPerPage,
  });

  final int pageNumber;
  final int itemsPerPage;

  @override
  int get limit => itemsPerPage;
}

/// Pagination from a specific transaction ID
class TransactionBasedPagination extends TransactionPagination {
  const TransactionBasedPagination({
    required this.fromId,
    required this.itemCount,
  });

  final String fromId;
  final int itemCount;

  @override
  int get limit => itemCount;
}

/// Pagination by block range
class BlockRangePagination extends TransactionPagination {
  const BlockRangePagination({
    required this.fromBlock,
    required this.toBlock,
    this.maxItems,
  });

  final int fromBlock;
  final int toBlock;
  final int? maxItems;

  @override
  int? get limit => maxItems;
}

/// Pagination by timestamp range
class TimestampRangePagination extends TransactionPagination {
  const TimestampRangePagination({
    required this.fromTimestamp,
    required this.toTimestamp,
    this.maxItems,
  });

  final DateTime fromTimestamp;
  final DateTime toTimestamp;
  final int? maxItems;

  @override
  int? get limit => maxItems;
}

/// Contract-specific pagination (e.g., for ERC20 token transfers)
class ContractEventPagination extends TransactionPagination {
  const ContractEventPagination({
    required this.contractAddress,
    required this.fromBlock,
    this.toBlock,
    this.maxItems,
  });

  final String contractAddress;
  final int fromBlock;
  final int? toBlock;
  final int? maxItems;

  @override
  int? get limit => maxItems;
}
