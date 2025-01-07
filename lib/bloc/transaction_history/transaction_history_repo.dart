import 'dart:async';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/types.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/utils.dart';

class TransactionHistoryRepo {
  TransactionHistoryRepo({
    KomodoDefiSdk? sdk,
  }) : _sdk = sdk;
  final KomodoDefiSdk? _sdk;

  Future<List<Transaction>?> fetch(Coin coin) async {
    final asset = getSdkAsset(_sdk, coin.abbr);

    try {
      final transactionHistory = await _sdk?.transactions.getTransactionHistory(
        asset,
        pagination: const PagePagination(
          pageNumber: 1,
          itemsPerPage: 200,
        ),
      );
      return transactionHistory?.transactions;
    } catch (e) {
      return null;
    }
  }

  /// Fetches transactions for the provided [coin] where the transaction
  /// timestamp is not 0 (transaction is completed and/or confirmed).
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
}

class TransactionFetchException implements Exception {
  TransactionFetchException(this.message);
  final String message;
}
