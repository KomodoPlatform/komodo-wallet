import 'package:web_dex/model/nft.dart';
import 'package:web_dex/model/withdraw_details/fee_details.dart';

class NftTxsResponse {
  NftTxsResponse({required this.transactions, this.errorMessage});

  factory NftTxsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> transferHistory = json['result']['transfer_history'];
    final result = transferHistory
        .map((e) => NftTransaction.fromJson(e))
        .toList();
    return NftTxsResponse(transactions: result);
  }

  final List<NftTransaction> transactions;
  final String? errorMessage;
}

enum NftTxnDetailsStatus { initial, success, failure }

class NftTransaction {
  NftTransaction({
    required this.chain,
    required this.blockNumber,
    this.confirmations,
    this.feeDetails,
    required this.blockTimestamp,
    required this.blockHash,
    required this.transactionHash,
    required this.transactionIndex,
    required this.logIndex,
    required this.value,
    required this.contractType,
    required this.transactionType,
    required this.tokenAddress,
    required this.tokenId,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.verified,
    this.operator,
    this.collectionName,
    this.image,
    this.tokenName,
    this.status,
    required this.possibleSpam,
  });

  final NftBlockchains chain;
  final int blockNumber;
  int? confirmations;
  FeeDetails? feeDetails;
  final DateTime blockTimestamp;
  final String? blockHash;
  final String transactionHash;
  final int? transactionIndex;
  final int? logIndex;
  final String? value;
  final String contractType;
  final String? transactionType;
  final String tokenAddress;
  final String tokenId;
  final String? collectionName;
  final String? image;
  final String? tokenName;
  final String fromAddress;
  final String toAddress;
  final String amount;
  final NftTransactionStatuses? status;
  final bool verified;
  final String? operator;
  final bool possibleSpam;
  NftTxnDetailsStatus _detailsFetchStatus = NftTxnDetailsStatus.initial;

  String getTxKey() {
    return '$tokenId-$transactionHash';
  }

  factory NftTransaction.fromJson(Map<String, dynamic> json) {
    return NftTransaction(
      chain: NftBlockchains.fromApiResponse(json['chain'] as String),
      blockNumber: json['block_number'],
      blockTimestamp: DateTime.fromMillisecondsSinceEpoch(
        json['block_timestamp'] * 1000,
      ),
      blockHash: json['block_hash'],
      confirmations: json['confirmations'],
      feeDetails: json['fee_details'] != null
          ? FeeDetails.fromJson(json['fee_details'])
          : null,
      transactionHash: json['transaction_hash'],
      transactionIndex: json['transaction_index'],
      logIndex: json['log_index'],
      value: json['value'],
      contractType: json['contract_type'],
      transactionType: json['transaction_type'],
      tokenAddress: json['token_address'],
      tokenId: json['token_id'],
      fromAddress: json['from_address'],
      toAddress: json['to_address'],
      status: NftTransactionStatuses.fromApi(json['status']),
      collectionName: json['collection_name'] as String?,
      image: json['image_url'] as String?,
      tokenName: json['token_name'] as String?,
      amount: json['amount'],
      verified: json['verified'] == 1,
      operator: json['operator'],
      possibleSpam: json['possible_spam'],
    );
  }

  NftTransaction copyWithProxyInfo(Map<String, dynamic> json) {
    final confirmations = json['confirmations'] ?? 0;
    final feeDetails = json['fee_details'] != null
        ? FeeDetails.fromJson(json['fee_details'])
        : FeeDetails.empty();
    return NftTransaction(
      chain: chain,
      blockNumber: blockNumber,
      blockTimestamp: blockTimestamp,
      blockHash: blockHash,
      confirmations: confirmations,
      feeDetails: feeDetails,
      transactionHash: transactionHash,
      transactionIndex: transactionIndex,
      logIndex: logIndex,
      value: value,
      contractType: contractType,
      transactionType: transactionType,
      tokenAddress: tokenAddress,
      tokenId: tokenId,
      fromAddress: fromAddress,
      toAddress: toAddress,
      status: status,
      collectionName: collectionName,
      image: image,
      tokenName: tokenName,
      amount: amount,
      verified: verified,
      operator: operator,
      possibleSpam: possibleSpam,
    );
  }

  bool get containsAdditionalInfo =>
      feeDetails != null && confirmations != null;

  String get name => tokenName ?? tokenId;
  String? get imageUrl {
    if (image == null) return null;
    // Image.network does not support ipfs
    return image?.replaceFirst('ipfs://', 'https://ipfs.io/ipfs/');
  }

  void setDetailsStatus(NftTxnDetailsStatus value) {
    _detailsFetchStatus = value;
  }

  NftTxnDetailsStatus get detailsFetchStatus => _detailsFetchStatus;
}

enum NftTransactionStatuses {
  receive,
  send;

  @override
  String toString() {
    switch (this) {
      case NftTransactionStatuses.receive:
        return 'Receive';
      case NftTransactionStatuses.send:
        return 'Send';
    }
  }

  static NftTransactionStatuses? fromApi(String? status) {
    switch (status) {
      case 'Receive':
        return NftTransactionStatuses.receive;
      case 'Send':
        return NftTransactionStatuses.send;
    }
    return null;
  }
}
