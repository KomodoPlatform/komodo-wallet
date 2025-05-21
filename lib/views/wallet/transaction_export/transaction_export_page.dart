import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/transaction_export/transaction_export_bloc.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_tx_history/transaction.dart';

class TransactionExportPage extends StatelessWidget {
  const TransactionExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionExportBloc(),
      child: const _TransactionExportView(),
    );
  }
}

class _TransactionExportView extends StatefulWidget {
  const _TransactionExportView();

  @override
  State<_TransactionExportView> createState() => _TransactionExportViewState();
}

class _TransactionExportViewState extends State<_TransactionExportView> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionExportBloc, TransactionExportState>(
      builder: (context, state) {
        switch (state.step) {
          case 0:
            return _buildUserInfo(context);
          case 1:
            return _buildSelectTransactions(context);
          case 2:
            return _buildPreview(context);
          default:
            return _buildComplete(context);
        }
      },
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.transactionExport.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(LocaleKeys.transactionExportUserInfoTitle.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: LocaleKeys.transactionExportFullName.tr(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: LocaleKeys.transactionExportEmail.tr(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                context.read<TransactionExportBloc>().add(
                      UserInfoSubmitted(
                        name: _nameCtrl.text,
                        email: _emailCtrl.text,
                        address: _addressCtrl.text,
                      ),
                    );
                context
                    .read<TransactionExportBloc>()
                    .add(const NextStepRequested());
              },
              child: Text(LocaleKeys.transactionExportContinue.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectTransactions(BuildContext context) {
    final txs = context.watch<TransactionHistoryBloc>().state.transactions;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.transactionExportSelectTxTitle.tr()),
        leading: BackButton(
          onPressed: () => context
              .read<TransactionExportBloc>()
              .add(const PreviousStepRequested()),
        ),
      ),
      body: ListView.builder(
        itemCount: txs.length,
        itemBuilder: (context, index) {
          final tx = txs[index];
          final selected =
              context.read<TransactionExportBloc>().state.selected.contains(tx);
          return CheckboxListTile(
            value: selected,
            title: Text(tx.txHash),
            subtitle: Text(
                DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000)
                    .toString()),
            onChanged: (_) {
              context.read<TransactionExportBloc>().add(ToggleTransaction(tx));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: context.read<TransactionExportBloc>().state.selected.isEmpty
            ? null
            : () => context
                .read<TransactionExportBloc>()
                .add(const NextStepRequested()),
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final state = context.watch<TransactionExportBloc>().state;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.transactionExportPreviewTitle.tr()),
        leading: BackButton(
          onPressed: () => context
              .read<TransactionExportBloc>()
              .add(const PreviousStepRequested()),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${state.name}'),
            Text('Email: ${state.email}'),
            Text('Address: ${state.address}'),
            const SizedBox(height: 16),
            Text('${state.selected.length} transactions selected'),
            const Spacer(),
            Text(LocaleKeys.transactionExportFormat.tr()),
            RadioListTile<ExportFormat>(
              title: Text(LocaleKeys.transactionExportCsv.tr()),
              value: ExportFormat.csv,
              groupValue: state.format,
              onChanged: (val) {
                if (val != null) {
                  context.read<TransactionExportBloc>().add(FormatChanged(val));
                }
              },
            ),
            RadioListTile<ExportFormat>(
              title: Text(LocaleKeys.transactionExportPdf.tr()),
              value: ExportFormat.pdf,
              groupValue: state.format,
              onChanged: (val) {
                if (val != null) {
                  context.read<TransactionExportBloc>().add(FormatChanged(val));
                }
              },
            ),
            RadioListTile<ExportFormat>(
              title: Text(LocaleKeys.transactionExportMarkdown.tr()),
              value: ExportFormat.markdown,
              groupValue: state.format,
              onChanged: (val) {
                if (val != null) {
                  context.read<TransactionExportBloc>().add(FormatChanged(val));
                }
              },
            ),
            ElevatedButton(
              onPressed: state.isExporting
                  ? null
                  : () => context
                      .read<TransactionExportBloc>()
                      .add(ExportRequested(state.format)),
              child: state.isExporting
                  ? const CircularProgressIndicator()
                  : Text(LocaleKeys.transactionExportExportButton.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(LocaleKeys.transactionExportCompleteTitle.tr())),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.transactionExportDone.tr()),
        ),
      ),
    );
  }
}
