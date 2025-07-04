import 'package:equatable/equatable.dart';
import 'package:komodo_wallet/mm2/rpc/nft_transaction/nft_transactions_response.dart';
import 'package:komodo_wallet/model/nft.dart';

class NftTransactionsFilter extends Equatable {
  const NftTransactionsFilter({
    this.statuses = const [],
    this.blockchain = const [],
    this.dateFrom,
    this.dateTo,
    this.searchLine = '',
  });

  factory NftTransactionsFilter.from(NftTransactionsFilter? data) {
    if (data == null) return const NftTransactionsFilter();

    return NftTransactionsFilter(
      statuses: data.statuses,
      blockchain: data.blockchain,
      dateFrom: data.dateFrom,
      dateTo: data.dateTo,
      searchLine: data.searchLine,
    );
  }

  NftTransactionsFilter copyWith({
    List<NftTransactionStatuses>? statuses,
    List<NftBlockchains>? blockchain,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? searchLine,
  }) {
    return NftTransactionsFilter(
      statuses: statuses ?? this.statuses,
      blockchain: blockchain ?? this.blockchain,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      searchLine: searchLine ?? this.searchLine,
    );
  }

  bool get isEmpty =>
      statuses.isEmpty &&
      blockchain.isEmpty &&
      dateFrom == null &&
      dateTo == null &&
      searchLine.isEmpty;

  int get count =>
      statuses.length +
      blockchain.length +
      (searchLine.isNotEmpty ? 1 : 0) +
      (dateFrom != null ? 1 : 0) +
      (dateTo != null ? 1 : 0);

  final List<NftTransactionStatuses> statuses;
  final List<NftBlockchains> blockchain;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String searchLine;

  @override
  List<Object?> get props => [
        statuses,
        blockchain,
        dateFrom,
        dateTo,
        searchLine,
      ];
}
