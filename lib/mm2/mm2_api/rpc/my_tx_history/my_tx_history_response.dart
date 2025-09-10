import 'package:web_dex/mm2/mm2_api/rpc/my_tx_history/transaction.dart';

class MyTxHistoryResponse {
  MyTxHistoryResponse({required this.result});

  factory MyTxHistoryResponse.fromJson(Map<String, dynamic> json) =>
      MyTxHistoryResponse(
        result: TransactionHistoryResponseResult.fromJson(
          json['result'] ?? <String, dynamic>{},
        ),
      );

  TransactionHistoryResponseResult result;
}

class TransactionHistoryResponseResult {
  TransactionHistoryResponseResult({
    required this.fromId,
    required this.currentBlock,
    required this.syncStatus,
    required this.limit,
    required this.skipped,
    required this.total,
    required this.transactions,
  });

  factory TransactionHistoryResponseResult.fromJson(
    Map<String, dynamic> json,
  ) => TransactionHistoryResponseResult(
    fromId: json['from_id'] ?? '',
    limit: json['limit'] ?? 0,
    skipped: json['skipped'] ?? 0,
    total: json['total'] ?? 0,
    currentBlock: json['current_block'] ?? 0,
    syncStatus: json['sync_status'] == null
        ? SyncStatus()
        : SyncStatus.fromJson(json['sync_status']),
    transactions: json['transactions'] is List
        ? List<Transaction>.from(
            json['transactions'].map((dynamic x) => Transaction.fromJson(x)),
          )
        : [],
  );

  final String fromId;
  final int currentBlock;
  final SyncStatus syncStatus;
  final int limit;
  final int skipped;
  final int total;
  final List<Transaction> transactions;
}

class SyncStatus {
  SyncStatus({this.state, this.additionalInfo});

  factory SyncStatus.fromJson(Map<String, dynamic> json) => SyncStatus(
    additionalInfo: json['additional_info'] == null
        ? null
        : AdditionalInfo.fromJson(json['additional_info']),
    state: _convertSyncStatusState(json['state']),
  );

  AdditionalInfo? additionalInfo;
  SyncStatusState? state;
}

class AdditionalInfo {
  AdditionalInfo({
    required this.code,
    required this.message,
    required this.transactionsLeft,
    required this.blocksLeft,
  });

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) => AdditionalInfo(
    code: json['code'] ?? 0,
    message: json['message'] ?? '',
    transactionsLeft: json['transactions_left'] ?? 0,
    blocksLeft: json['blocks_left'] ?? 0,
  );

  int code;
  String message;
  int transactionsLeft;
  int blocksLeft;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'message': message,
    'transactions_left': transactionsLeft,
    'blocks_left': blocksLeft,
  };
}

SyncStatusState? _convertSyncStatusState(String? state) {
  switch (state) {
    case 'NotEnabled':
      return SyncStatusState.notEnabled;
    case 'NotStarted':
      return SyncStatusState.notStarted;
    case 'InProgress':
      return SyncStatusState.inProgress;
    case 'Error':
      return SyncStatusState.error;
    case 'Finished':
      return SyncStatusState.finished;
  }
  return null;
}

enum SyncStatusState { notEnabled, notStarted, inProgress, error, finished }
