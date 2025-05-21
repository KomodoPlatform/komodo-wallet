part of 'transaction_export_bloc.dart';

enum ExportFormat { csv, pdf, markdown }

class TransactionExportState extends Equatable {
  const TransactionExportState({
    this.step = 0,
    this.name = '',
    this.email = '',
    this.address = '',
    this.selected = const [],
    this.isExporting = false,
    this.format = ExportFormat.csv,
  });

  final int step;
  final String name;
  final String email;
  final String address;
  final List<Transaction> selected;
  final bool isExporting;
  final ExportFormat format;

  TransactionExportState copyWith({
    int? step,
    String? name,
    String? email,
    String? address,
    List<Transaction>? selected,
    bool? isExporting,
    ExportFormat? format,
  }) {
    return TransactionExportState(
      step: step ?? this.step,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      selected: selected ?? this.selected,
      isExporting: isExporting ?? this.isExporting,
      format: format ?? this.format,
    );
  }

  @override
  List<Object?> get props =>
      [step, name, email, address, selected, isExporting, format];
}
