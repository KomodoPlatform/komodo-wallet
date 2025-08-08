import 'package:web_dex/mm2/mm2_api/rpc/my_tx_history/transaction.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

class MyTxHistoryResponse {
  MyTxHistoryResponse({required this.result});

  factory MyTxHistoryResponse.fromJson(JsonMap json) => MyTxHistoryResponse(
    result: TransactionHistoryResponseResult.fromJson(
      json.value<JsonMap>('result'),
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

  factory TransactionHistoryResponseResult.fromJson(JsonMap json) =>
      TransactionHistoryResponseResult(
        fromId: json.valueOrNull<String>('from_id') ?? '',
        limit: json.value<int>('limit'),
        skipped: json.value<int>('skipped'),
        total: json.value<int>('total'),
        currentBlock: json.value<int>('current_block'),
        syncStatus: json.valueOrNull<JsonMap>('sync_status') != null
            ? SyncStatus.fromJson(json.value<JsonMap>('sync_status'))
            : SyncStatus(),
        transactions: json
            .value<List<JsonMap>>('transactions')
            .map((JsonMap x) => Transaction.fromJson(x))
            .toList(),
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

  factory SyncStatus.fromJson(JsonMap json) => SyncStatus(
    additionalInfo: json.valueOrNull<JsonMap>('additional_info') != null
        ? AdditionalInfo.fromJson(json.value<JsonMap>('additional_info'))
        : null,
    state: _convertSyncStatusState(json.value<String>('state')),
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

  factory AdditionalInfo.fromJson(JsonMap json) => AdditionalInfo(
    code: json.value<int>('code'),
    message: json.valueOrNull<String>('message') ?? '',
    transactionsLeft: json.value<int>('transactions_left'),
    blocksLeft: json.value<int>('blocks_left'),
  );

  int code;
  String message;
  int transactionsLeft;
  int blocksLeft;

  JsonMap toJson() => <String, dynamic>{
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
