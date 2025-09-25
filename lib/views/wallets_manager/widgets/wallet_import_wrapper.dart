import 'package:flutter/material.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_import_by_file.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_simple_import.dart';

class WalletImportWrapper extends StatefulWidget {
  const WalletImportWrapper({
    Key? key,
    required this.onImport,
    required this.onCancel,
  }) : super(key: key);

  final void Function({
    required String name,
    required String password,
    required WalletConfig walletConfig,
    required bool rememberMe,
  })
  onImport;
  final void Function() onCancel;

  @override
  State<WalletImportWrapper> createState() => _WalletImportWrapperState();
}

class _WalletImportWrapperState extends State<WalletImportWrapper> {
  WalletImportTypes _importType = WalletImportTypes.simple;
  WalletFileData? _fileData;

  @override
  Widget build(BuildContext context) {
    return _importType == WalletImportTypes.simple
        ? _buildSimpleImport()
        : _buildFileImport();
  }

  Widget _buildSimpleImport() {
    return WalletSimpleImport(
      onImport: widget.onImport,
      onUploadFiles: _onUploadFiles,
      onCancel: _onCancel,
    );
  }

  Widget _buildFileImport() {
    final WalletFileData? fileData = _fileData;
    assert(fileData != null);
    if (fileData != null) {
      return WalletImportByFile(
        fileData: fileData,
        onImport: widget.onImport,
        onCancel: _onCancel,
      );
    }
    return const SizedBox();
  }

  void _onUploadFiles({
    required LoadedFileData fileData,
    required String fileName,
  }) {
    setState(() {
      _fileData = WalletFileData(
        name: fileName,
        text: fileData.text,
        bytes: fileData.bytes,
      );
      _importType = WalletImportTypes.file;
    });
  }

  void _onCancel() {
    if (_importType == WalletImportTypes.file) {
      setState(() {
        _importType = WalletImportTypes.simple;
        _fileData = null;
      });
      return;
    }

    widget.onCancel();
  }
}

enum WalletImportTypes { simple, file }
