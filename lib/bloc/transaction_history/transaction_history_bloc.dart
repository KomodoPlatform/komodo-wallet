import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_event.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_defi_types/types.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/utils.dart';

class TransactionHistoryBloc
    extends Bloc<TransactionHistoryEvent, TransactionHistoryState> {
  TransactionHistoryBloc({
    required TransactionHistoryRepo repo,
  })  : _repo = repo,
        super(const TransactionHistoryState.initial()) {
    on<TransactionHistorySubscribe>(_onSubscribe);
    on<TransactionHistoryUnsubscribe>(_onUnsubscribe);
    on<TransactionHistoryStartedLoading>(_onStartedLoading);
    on<TransactionHistoryUpdated>(_onUpdated);
    on<TransactionHistoryFailure>(_onFailure);
  }

  final TransactionHistoryRepo _repo;
  Timer? _updateTransactionsTimer;
  final _updateTime = const Duration(seconds: 10);

  Future<void> _onSubscribe(
    TransactionHistorySubscribe event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    if (!hasTxHistorySupport(event.coin)) {
      return;
    }
    emit(const TransactionHistoryState.initial());
    await _update(event.coin);
    _stopTimers();
    _updateTransactionsTimer = Timer.periodic(_updateTime, (_) async {
      await _update(event.coin);
    });
  }

  void _onUnsubscribe(
    TransactionHistoryUnsubscribe event,
    Emitter<TransactionHistoryState> emit,
  ) {
    _stopTimers();
  }

  void _onUpdated(
    TransactionHistoryUpdated event,
    Emitter<TransactionHistoryState> emit,
  ) {
    emit(state.copyWith(
      transactions: event.transactions,
      loading: false,
    ));
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
    emit(state.copyWith(
      loading: false,
      error: event.error,
    ));
  }

  Future<void> _update(Coin coin) async {
    if (isClosed) {
      return;
    }

    try {
      add(const TransactionHistoryStartedLoading());
      final transactions = await _repo.fetch(coin);
      if (isClosed) {
        return;
      }

      if (transactions == null) {
        add(
          TransactionHistoryFailure(
            error: TextError(error: LocaleKeys.somethingWrong.tr()),
          ),
        );
        return;
      }

      transactions.sort(_sortTransactions);
      _flagTransactions(transactions, coin);

      add(TransactionHistoryUpdated(transactions: transactions));
    } catch (e) {
      add(
        TransactionHistoryFailure(
          error: TextError(error: LocaleKeys.somethingWrong.tr()),
        ),
      );
      return;
    }
  }

  @override
  Future<void> close() {
    _stopTimers();

    return super.close();
  }

  void _stopTimers() {
    _updateTransactionsTimer?.cancel();
    _updateTransactionsTimer = null;
  }
}

int _sortTransactions(Transaction tx1, Transaction tx2) {
  if (tx2.timestamp == DateTime.fromMillisecondsSinceEpoch(0)) {
    return 1;
  } else if (tx1.timestamp == DateTime.fromMillisecondsSinceEpoch(0)) {
    return -1;
  }
  return tx2.timestamp.compareTo(tx1.timestamp);
}

void _flagTransactions(List<Transaction> transactions, Coin coin) {
  // First response to https://trezor.io/support/a/address-poisoning-attacks,
  // need to be refactored.
  // ref: https://github.com/KomodoPlatform/komodowallet/issues/1091

  if (!coin.isErcType) return;

  for (final Transaction tx in List.from(transactions)) {
    if (tx.balanceChanges.totalAmount.toDouble() == 0.0) {
      transactions.remove(tx);
    }
  }
}
