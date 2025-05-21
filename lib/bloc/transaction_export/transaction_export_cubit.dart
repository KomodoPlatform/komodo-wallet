import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';

part 'transaction_export_state.dart';

class TransactionExportCubit extends Cubit<TransactionExportState> {
  TransactionExportCubit() : super(const TransactionExportState());

  void setUserInfo(
      {required String name, required String email, required String address}) {
    emit(state.copyWith(name: name, email: email, address: address));
  }

  void nextStep() => emit(state.copyWith(step: state.step + 1));

  void previousStep() => emit(state.copyWith(step: state.step - 1));

  void toggleTransaction(Transaction tx) {
    final current = List<Transaction>.from(state.selected);
    if (current.contains(tx)) {
      current.remove(tx);
    } else {
      current.add(tx);
    }
    emit(state.copyWith(selected: current));
  }

  Future<void> export() async {
    emit(state.copyWith(isExporting: true));
    final fileLoader = FileLoader.fromPlatform();
    final data = {
      'name': state.name,
      'email': state.email,
      'address': state.address,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': state.selected
          .map((e) => {
                'tx_hash': e.txHash,
                'asset': e.assetId.id,
                'timestamp': e.timestamp.toIso8601String(),
                'amount': e.balanceChanges.totalAmount.toString(),
              })
          .toList(),
    };
    await fileLoader.save(
      fileName: 'transactions_export',
      data: jsonEncode(data),
      type: LoadFileType.text,
    );
    emit(state.copyWith(isExporting: false, step: 3));
  }
}
