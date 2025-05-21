part of 'transaction_export_bloc.dart';

abstract class TransactionExportEvent {
  const TransactionExportEvent();
}

class UserInfoSubmitted extends TransactionExportEvent {
  const UserInfoSubmitted(
      {required this.name, required this.email, required this.address});
  final String name;
  final String email;
  final String address;
}

class NextStepRequested extends TransactionExportEvent {
  const NextStepRequested();
}

class PreviousStepRequested extends TransactionExportEvent {
  const PreviousStepRequested();
}

class ToggleTransaction extends TransactionExportEvent {
  const ToggleTransaction(this.tx);
  final Transaction tx;
}

class ExportRequested extends TransactionExportEvent {
  const ExportRequested(this.format);
  final ExportFormat format;
}

class FormatChanged extends TransactionExportEvent {
  const FormatChanged(this.format);
  final ExportFormat format;
}
