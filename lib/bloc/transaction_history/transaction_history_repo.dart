import 'dart:async';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/types.dart';
import 'package:web_dex/model/coin.dart';

abstract class TransactionHistoryRepo {
  Future<List<Transaction>?> fetch(Coin coin);
  Future<List<Transaction>> fetchTransactions(Coin coin);
  Future<List<Transaction>> fetchCompletedTransactions(Coin coin);
}

class SdkTransactionHistoryRepository implements TransactionHistoryRepo {
  SdkTransactionHistoryRepository({
    required KomodoDefiSdk sdk,
  }) : _sdk = sdk;
  final KomodoDefiSdk _sdk;

  @override
  Future<List<Transaction>?> fetch(Coin coin) async {
    try {
      final asset = _sdk.assets.available[coin.id]!;
      final transactionHistory = await _sdk.transactions.getTransactionHistory(
        asset,
        pagination: const PagePagination(
          pageNumber: 1,
          itemsPerPage: 200,
        ),
      );
      return transactionHistory.transactions;
    } catch (e) {
      return null;
    }
  }

  /// Fetches transactions for the provided [coin] where the transaction
  /// timestamp is not 0 (transaction is completed and/or confirmed).
  @override
  Future<List<Transaction>> fetchCompletedTransactions(Coin coin) async {
    final List<Transaction> transactions = (await fetch(coin) ?? [])
      ..sort(
        (a, b) => a.timestamp.compareTo(b.timestamp),
      )
      ..removeWhere(
        (transaction) =>
            transaction.timestamp == DateTime.fromMillisecondsSinceEpoch(0),
      );
    return transactions;
  }

  @override
  Future<List<Transaction>> fetchTransactions(Coin coin) async {
    return await fetch(coin) ?? [];
  }
}

class TransactionFetchException implements Exception {
  TransactionFetchException(this.message);
  final String message;
}
