part of 'transaction_export_cubit.dart';

class TransactionExportState {
  const TransactionExportState({
    this.step = 0,
    this.name = '',
    this.email = '',
    this.address = '',
    this.selected = const [],
    this.isExporting = false,
  });

  final int step;
  final String name;
  final String email;
  final String address;
  final List<Transaction> selected;
  final bool isExporting;

  TransactionExportState copyWith({
    int? step,
    String? name,
    String? email,
    String? address,
    List<Transaction>? selected,
    bool? isExporting,
  }) {
    return TransactionExportState(
      step: step ?? this.step,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      selected: selected ?? this.selected,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}
