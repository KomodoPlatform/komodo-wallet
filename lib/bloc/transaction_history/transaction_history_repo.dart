import 'dart:async';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

/// Throws [TransactionFetchException] if the transaction history could not be
/// fetched.
abstract class TransactionHistoryRepo {
  Future<List<Transaction>?> fetch(AssetId assetId);
  Future<List<Transaction>> fetchCompletedTransactions(AssetId assetId);
}

class SdkTransactionHistoryRepository implements TransactionHistoryRepo {
  SdkTransactionHistoryRepository({required KomodoDefiSdk sdk}) : _sdk = sdk;
  final KomodoDefiSdk _sdk;

  @override
  Future<List<Transaction>?> fetch(AssetId assetId, {String? fromId}) async {
    final asset = _sdk.assets.available[assetId];
    if (asset == null) {
      throw TransactionFetchException('Asset $assetId not found');
    }

    try {
      final transactionHistory = await _sdk.transactions.getTransactionHistory(
        asset,
        pagination: fromId == null
            ? const PagePagination(
                pageNumber: 1,
                // TODO: Handle cases with more than 2000 transactions and/or
                // adopt a pagination strategy. Migrate form
                itemsPerPage: 2000,
              )
            : TransactionBasedPagination(fromId: fromId, itemCount: 2000),
      );
      return transactionHistory.transactions;
    } catch (e) {
      return null;
    }
  }

  /// Fetches transactions for the provided [coin] where the transaction
  /// timestamp is not 0 (transaction is completed and/or confirmed).
  @override
  Future<List<Transaction>> fetchCompletedTransactions(AssetId assetId) async {
    final List<Transaction> transactions = (await fetch(assetId) ?? [])
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp))
      ..removeWhere(
        (transaction) =>
            transaction.timestamp == DateTime.fromMillisecondsSinceEpoch(0),
      );
    return transactions;
  }
}

class TransactionFetchException implements Exception {
  TransactionFetchException(this.message);
  final String message;
}
