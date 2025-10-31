import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_sdk/src/activation/activation_exceptions.dart';
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
  TransactionHistoryBloc({required KomodoDefiSdk sdk})
    : _sdk = sdk,
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
  // Stable in-memory clock for transactions that arrive with a zero timestamp.
  // Ensures deterministic ordering of unconfirmed and just-confirmed items.
  final Map<String, DateTime> _firstSeenAtById = {};

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
      _firstSeenAtById.clear();

      add(const TransactionHistoryStartedLoading());
      final asset = _sdk.assets.available[event.coin.id];
      if (asset == null) {
        throw Exception('Asset ${event.coin.id} not found in known coins list');
      }

      final pubkeys =
          _sdk.pubkeys.lastKnown(asset.id) ??
          await _sdk.pubkeys.getPubkeys(asset);
      final myAddresses = pubkeys.keys.map((p) => p.address).toSet();

      // Subscribe to historical transactions
      _historySubscription = _sdk.transactions
          .getTransactionsStreamed(asset)
          .listen(
            (newTransactions) {
              if (newTransactions.isEmpty) return;

              // Merge incoming batch by internalId, updating confirmations and other fields
              final Map<String, Transaction> byId = {
                for (final t in state.transactions) t.internalId: t,
              };

              for (final tx in newTransactions) {
                final sanitized = tx.sanitize(myAddresses);
                // Capture first-seen time for stable ordering where timestamp may be zero
                _firstSeenAtById.putIfAbsent(
                  sanitized.internalId,
                  () => sanitized.timestamp.millisecondsSinceEpoch != 0
                      ? sanitized.timestamp
                      : DateTime.now(),
                );
                final existing = byId[sanitized.internalId];
                if (existing == null) {
                  byId[sanitized.internalId] = sanitized;
                  _processedTxIds.add(sanitized.internalId);
                  continue;
                }

                // Update existing entry with fresher data (confirmations, blockHeight, fee, memo)
                byId[sanitized.internalId] = existing.copyWith(
                  confirmations: sanitized.confirmations,
                  blockHeight: sanitized.blockHeight,
                  fee: sanitized.fee ?? existing.fee,
                  memo: sanitized.memo ?? existing.memo,
                );
              }

              final updatedTransactions = byId.values.toList()
                ..sort(_compareTransactions);

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
                add(
                  TransactionHistoryUpdated(transactions: state.transactions),
                );
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

      String errorMessage;
      if (e is ActivationFailedException) {
        errorMessage = 'Asset activation failed: ${e.message}';
      } else {
        errorMessage = LocaleKeys.somethingWrong.tr();
      }

      add(TransactionHistoryFailure(error: TextError(error: errorMessage)));
    }
  }

  void _subscribeToNewTransactions(
    Asset asset,
    Coin coin,
    Set<String> myAddresses,
  ) {
    _newTransactionsSubscription = _sdk.transactions
        .watchTransactions(asset)
        .listen(
          (newTransaction) {
            final sanitized = newTransaction.sanitize(myAddresses);
            // Capture first-seen time once for stable ordering when timestamp is zero
            _firstSeenAtById.putIfAbsent(
              sanitized.internalId,
              () => sanitized.timestamp.millisecondsSinceEpoch != 0
                  ? sanitized.timestamp
                  : DateTime.now(),
            );

            // Merge single update by internalId
            final Map<String, Transaction> byId = {
              for (final t in state.transactions) t.internalId: t,
            };

            final existing = byId[sanitized.internalId];
            if (existing == null) {
              byId[sanitized.internalId] = sanitized;
            } else {
              byId[sanitized.internalId] = existing.copyWith(
                confirmations: sanitized.confirmations,
                blockHeight: sanitized.blockHeight,
                fee: sanitized.fee ?? existing.fee,
                memo: sanitized.memo ?? existing.memo,
                // Update the timestamp to change date from "Now" once tx
                // is confirmed on the blockchain
                timestamp: sanitized.timestamp,
              );
            }

            _processedTxIds.add(sanitized.internalId);

            final updatedTransactions = byId.values.toList()
              ..sort(_compareTransactions);

            if (coin.isErcType) {
              _flagTransactions(updatedTransactions, coin);
            }

            add(TransactionHistoryUpdated(transactions: updatedTransactions));
          },
          onError: (error) {
            String errorMessage;
            if (error is ActivationFailedException) {
              errorMessage = 'Asset activation failed: ${error.message}';
            } else {
              errorMessage = LocaleKeys.somethingWrong.tr();
            }

            add(
              TransactionHistoryFailure(error: TextError(error: errorMessage)),
            );
          },
        );
  }

  void _onUpdated(
    TransactionHistoryUpdated event,
    Emitter<TransactionHistoryState> emit,
  ) {
    emit(state.copyWith(transactions: event.transactions, loading: false));
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
    emit(state.copyWith(loading: false, error: event.error));
  }

  DateTime _sortTime(Transaction tx) {
    if (tx.timestamp.millisecondsSinceEpoch != 0) return tx.timestamp;
    final firstSeen = _firstSeenAtById[tx.internalId];
    return firstSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _compareTransactions(Transaction left, Transaction right) {
    // Unconfirmed (pending) transactions should appear first.
    // Because tx stream events don't include confirmations, only consider
    // 0 confirmations AND 0 timestamp as unconfirmed (1970)
    final leftIsUnconfirmed =
        left.confirmations == 0 && left.timestamp.millisecondsSinceEpoch == 0;
    final rightIsUnconfirmed =
        right.confirmations == 0 && right.timestamp.millisecondsSinceEpoch == 0;

    if (leftIsUnconfirmed != rightIsUnconfirmed) {
      return leftIsUnconfirmed ? -1 : 1;
    }

    // Within each group, sort by effective time (handles zero timestamps)
    final timeComparison = _sortTime(right).compareTo(_sortTime(left));
    if (timeComparison != 0) return timeComparison;

    // Prefer higher block heights first
    final heightComparison = right.blockHeight.compareTo(left.blockHeight);
    if (heightComparison != 0) return heightComparison;

    // Final tiebreaker to ensure deterministic ordering
    return right.internalId.compareTo(left.internalId);
  }
}

// Instance comparator now used; legacy top-level comparator removed.

void _flagTransactions(List<Transaction> transactions, Coin coin) {
  if (!coin.isErcType) return;
  transactions.removeWhere(
    (tx) => tx.balanceChanges.totalAmount.toDouble() == 0.0,
  );
}

class Pagination {
  Pagination({this.fromId, this.pageNumber});
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
  const PagePagination({required this.pageNumber, required this.itemsPerPage});

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
