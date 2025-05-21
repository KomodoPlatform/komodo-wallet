import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_tx_history/transaction.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';

part 'transaction_export_event.dart';
part 'transaction_export_state.dart';

class TransactionExportBloc
    extends Bloc<TransactionExportEvent, TransactionExportState> {
  TransactionExportBloc() : super(const TransactionExportState()) {
    on<UserInfoSubmitted>(_onUserInfoSubmitted);
    on<NextStepRequested>(_onNextStep);
    on<PreviousStepRequested>(_onPreviousStep);
    on<ToggleTransaction>(_onToggleTransaction);
    on<ExportRequested>(_onExportRequested);
    on<FormatChanged>(_onFormatChanged);
  }

  void _onUserInfoSubmitted(
      UserInfoSubmitted event, Emitter<TransactionExportState> emit) {
    emit(state.copyWith(
        name: event.name, email: event.email, address: event.address));
  }

  void _onNextStep(
      NextStepRequested event, Emitter<TransactionExportState> emit) {
    emit(state.copyWith(step: state.step + 1));
  }

  void _onPreviousStep(
      PreviousStepRequested event, Emitter<TransactionExportState> emit) {
    emit(state.copyWith(step: state.step - 1));
  }

  void _onToggleTransaction(
      ToggleTransaction event, Emitter<TransactionExportState> emit) {
    final current = List<Transaction>.from(state.selected);
    if (current.contains(event.tx)) {
      current.remove(event.tx);
    } else {
      current.add(event.tx);
    }
    emit(state.copyWith(selected: current));
  }

  void _onFormatChanged(
      FormatChanged event, Emitter<TransactionExportState> emit) {
    emit(state.copyWith(format: event.format));
  }

  Future<void> _onExportRequested(
      ExportRequested event, Emitter<TransactionExportState> emit) async {
    emit(state.copyWith(isExporting: true));
    final fileLoader = FileLoader.fromPlatform();
    late final String data;
    late final String ext;
    switch (event.format) {
      case ExportFormat.csv:
        data = _generateCsv();
        ext = 'csv';
        break;
      case ExportFormat.pdf:
        data = _generatePdf();
        ext = 'pdf';
        break;
      case ExportFormat.markdown:
        data = _generateMarkdown();
        ext = 'md';
        break;
    }
    await fileLoader.save(
      fileName: 'transactions_export',
      data: data,
      type: LoadFileType.text,
      extension: ext,
    );
    emit(state.copyWith(isExporting: false, step: 3));
  }

  String _generateCsv() {
    final buffer = StringBuffer();
    buffer.writeln('name,email,address,exportedAt');
    buffer.writeln(
        '${state.name},${state.email},${state.address},${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('tx_hash,coin,timestamp,amount');
    for (final tx in state.selected) {
      buffer
          .writeln('${tx.txHash},${tx.coin},${tx.timestamp},${tx.totalAmount}');
    }
    return buffer.toString();
  }

  String _generateMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Transaction Export');
    buffer.writeln('**Name:** ${state.name}  ');
    buffer.writeln('**Email:** ${state.email}  ');
    buffer.writeln('**Address:** ${state.address}  ');
    buffer.writeln('**Exported:** ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('| tx_hash | coin | timestamp | amount |');
    buffer.writeln('| --- | --- | --- | --- |');
    for (final tx in state.selected) {
      final time = DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000);
      buffer
          .writeln('| ${tx.txHash} | ${tx.coin} | $time | ${tx.totalAmount} |');
    }
    return buffer.toString();
  }

  String _escapePdf(String input) {
    return input
        .replaceAll('\\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }

  String _generatePdf() {
    final lines = <String>[
      'Transaction Export',
      'Name: ${state.name}',
      'Email: ${state.email}',
      'Address: ${state.address}',
      'Exported: ${DateTime.now().toIso8601String()}',
      ''
    ];
    for (final tx in state.selected) {
      final time = DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000);
      lines.add('${tx.txHash} ${tx.coin} $time ${tx.totalAmount}');
    }
    return _simplePdf(lines);
  }

  String _simplePdf(List<String> lines) {
    final objects = <String>[];
    objects.add('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj');
    objects.add('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj');
    final content = _pdfContent(lines);
    objects.add(
        '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj');
    objects.add(
        '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj');
    objects.add(
        '4 0 obj\n<< /Length ${content.length} >>\nstream\n$content\nendstream\nendobj');

    final buffer = StringBuffer('%PDF-1.1\n');
    final offsets = <int>[];
    for (final obj in objects) {
      offsets.add(buffer.length);
      buffer.writeln(obj);
    }
    final xrefStart = buffer.length;
    buffer.writeln('xref');
    buffer.writeln('0 ${objects.length + 1}');
    buffer.writeln('0000000000 65535 f ');
    for (final off in offsets) {
      buffer.writeln('${off.toString().padLeft(10, '0')} 00000 n ');
    }
    buffer.writeln('trailer');
    buffer.writeln('<< /Root 1 0 R /Size ${objects.length + 1} >>');
    buffer.writeln('startxref');
    buffer.writeln(xrefStart);
    buffer.writeln('%%EOF');
    return buffer.toString();
  }

  String _pdfContent(List<String> lines) {
    final sb = StringBuffer();
    sb.writeln('BT');
    sb.writeln('/F1 12 Tf');
    sb.writeln('50 750 Td');
    var first = true;
    for (final line in lines) {
      if (!first) sb.writeln('T*');
      sb.writeln('(${_escapePdf(line)}) Tj');
      first = false;
    }
    sb.writeln('ET');
    return sb.toString();
  }
}
