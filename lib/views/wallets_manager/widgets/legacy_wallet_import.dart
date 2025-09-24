import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/legacy_wallet_data.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/services/legacy_wallet_migration_service.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/wallets_manager/widgets/hdwallet_mode_switch.dart';

/// Widget for importing legacy desktop wallet files
class LegacyWalletImport extends StatefulWidget {
  const LegacyWalletImport({
    required this.onImport,
    required this.onCancel,
    super.key,
  });

  final void Function({
    required String name,
    required String password,
    required WalletConfig walletConfig,
    LegacyWalletData? legacyData,
  }) onImport;

  final void Function() onCancel;

  @override
  State<LegacyWalletImport> createState() => _LegacyWalletImportState();
}

enum LegacyWalletImportStep { selectFile, enterPasswords, reviewData }

class _LegacyWalletImportState extends State<LegacyWalletImport> {
  LegacyWalletImportStep _step = LegacyWalletImportStep.selectFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _legacyPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _inProgress = false;
  bool _isHdMode = true;
  String? _filePasswordError;
  String? _commonError;
  Uint8List? _fileData;
  String _fileName = '';
  LegacyWalletData? _legacyData;

  final LegacyWalletMigrationService _migrationService =
      LegacyWalletMigrationService();

  @override
  void dispose() {
    _nameController.dispose();
    _legacyPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepContent(),
          const SizedBox(height: 20),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case LegacyWalletImportStep.selectFile:
        return _buildFileSelection();
      case LegacyWalletImportStep.enterPasswords:
        return _buildPasswordEntry();
      case LegacyWalletImportStep.reviewData:
        return _buildDataReview();
    }
  }

  Widget _buildFileSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.walletImportTitle.tr(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          LocaleKeys.walletImportByFileDescription.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Tip: On web, you can select your legacy \'*.seed\' file directly.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        UiPrimaryButton(
          onPressed: _selectFile,
          text: _fileName.isEmpty
              ? 'Select Legacy Wallet File (.seed/.wallet)'
              : 'Change File',
        ),
        if (_fileName.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected file: $_fileName',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_commonError != null) ...[
          const SizedBox(height: 16),
          Text(
            _commonError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.walletImportCreatePasswordTitle.tr(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        UiTextFormField(
          controller: _nameController,
          validator: _validateWalletName,
          hintText: LocaleKeys.walletCreationNameHint.tr(),
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        UiTextFormField(
          controller: _legacyPasswordController,
          validator: _validateLegacyPassword,
          hintText: 'Legacy Wallet Password',
          obscureText: true,
          autocorrect: false,
        ),
        if (_filePasswordError != null) ...[
          const SizedBox(height: 8),
          Text(
            _filePasswordError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        UiTextFormField(
          controller: _newPasswordController,
          validator: _validateNewPassword,
          hintText: LocaleKeys.walletCreationPasswordHint.tr(),
          obscureText: true,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        UiTextFormField(
          controller: _confirmPasswordController,
          validator: _validateConfirmPassword,
          hintText: LocaleKeys.walletCreationConfirmPasswordHint.tr(),
          obscureText: true,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        HDWalletModeSwitch(
          value: _isHdMode,
          onChanged: (value) {
            setState(() {
              _isHdMode = value;
            });
          },
        ),
        if (_commonError != null) ...[
          const SizedBox(height: 16),
          Text(
            _commonError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataReview() {
    if (_legacyData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Imported Data',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _buildDataSummary(),
        if (_commonError != null) ...[
          const SizedBox(height: 16),
          Text(
            _commonError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataSummary() {
    if (_legacyData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Wallet Name', _legacyData!.walletName),
            _buildSummaryRow(
              'Address Book Entries',
              '${_legacyData!.addressBook.length}',
            ),
            _buildSummaryRow(
              'Swap History Entries',
              '${_legacyData!.swapHistory.length}',
            ),
            _buildSummaryRow(
              'Maker Orders',
              '${_legacyData!.makerOrders.length}',
            ),
            _buildSummaryRow(
              'Makerbot Configs',
              '${_legacyData!.makerbotConfigs.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: UiPrimaryButton(
            onPressed: _inProgress ? null : _onPrimaryButton,
            text: _getPrimaryButtonText(),
          ),
        ),
        const SizedBox(width: 16),
        UiUnderlineTextButton(
          onPressed: _inProgress ? null : _onSecondaryButton,
          text: _getSecondaryButtonText(),
        ),
      ],
    );
  }

  String _getPrimaryButtonText() {
    switch (_step) {
      case LegacyWalletImportStep.selectFile:
        return LocaleKeys.next.tr();
      case LegacyWalletImportStep.enterPasswords:
        return 'Decrypt and Review';
      case LegacyWalletImportStep.reviewData:
        return LocaleKeys.import.tr();
    }
  }

  String _getSecondaryButtonText() {
    switch (_step) {
      case LegacyWalletImportStep.selectFile:
        return LocaleKeys.cancel.tr();
      case LegacyWalletImportStep.enterPasswords:
      case LegacyWalletImportStep.reviewData:
        return LocaleKeys.back.tr();
    }
  }

  Future<void> _selectFile() async {
    try {
      await FileLoader.fromPlatform().uploadBytes(
        onUpload: (fileName, bytes) {
          setState(() {
            _fileName = fileName;
            _fileData = bytes;
            _commonError = null;
          });
        },
        onError: (String error) {
          setState(() {
            _commonError = error;
          });
          log(error, path: 'LegacyWalletImport._selectFile', isError: true);
        },
      );
    } catch (e) {
      setState(() {
        _commonError = 'Failed to load file';
      });
    }
  }

  void _onPrimaryButton() {
    switch (_step) {
      case LegacyWalletImportStep.selectFile:
        _validateFileAndProceed();
        break;
      case LegacyWalletImportStep.enterPasswords:
        _decryptAndReview();
        break;
      case LegacyWalletImportStep.reviewData:
        _importWallet();
        break;
    }
  }

  void _onSecondaryButton() {
    switch (_step) {
      case LegacyWalletImportStep.selectFile:
        widget.onCancel();
        break;
      case LegacyWalletImportStep.enterPasswords:
        setState(() {
          _step = LegacyWalletImportStep.selectFile;
          _commonError = null;
          _filePasswordError = null;
        });
        break;
      case LegacyWalletImportStep.reviewData:
        setState(() {
          _step = LegacyWalletImportStep.enterPasswords;
          _commonError = null;
        });
        break;
    }
  }

  void _validateFileAndProceed() {
    if (_fileData == null || _fileData!.isEmpty) {
      setState(() {
        _commonError = 'Please select a file';
      });
      return;
    }

    if (!_migrationService.isLegacyDesktopFormat(_fileData!)) {
      setState(() {
        _commonError = 'Not a legacy wallet file';
      });
      return;
    }

    setState(() {
      _step = LegacyWalletImportStep.enterPasswords;
      _commonError = null;
      // Pre-fill wallet name from file name
      if (_nameController.text.isEmpty) {
        _nameController.text = _fileName.split('.').first;
      }
    });
  }

  Future<void> _decryptAndReview() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _inProgress = true;
      _commonError = null;
      _filePasswordError = null;
    });

    try {
      final legacyData = await _migrationService.migrateLegacyWallet(
        fileData: _fileData!,
        password: _legacyPasswordController.text,
        newWalletName: _nameController.text,
      );

      if (legacyData == null) {
        setState(() {
          _filePasswordError = LocaleKeys.incorrectPassword.tr();
          _inProgress = false;
        });
        return;
      }

      if (!_migrationService.validateLegacyData(legacyData)) {
        setState(() {
          _commonError = 'Invalid legacy wallet data';
          _inProgress = false;
        });
        return;
      }

      setState(() {
        _legacyData = legacyData;
        _step = LegacyWalletImportStep.reviewData;
        _inProgress = false;
      });
    } catch (e) {
      setState(() {
        _commonError = 'Failed to decrypt wallet';
        _inProgress = false;
      });
      log(
        'Failed to decrypt legacy wallet: $e',
        path: 'LegacyWalletImport._decryptAndReview',
        isError: true,
      );
    }
  }

  Future<void> _importWallet() async {
    if (_legacyData == null) return;

    setState(() {
      _inProgress = true;
      _commonError = null;
    });

    try {
      final walletConfig = await _migrationService.convertToWalletConfig(
        legacyData: _legacyData!,
        walletType: _isHdMode ? WalletType.hdwallet : WalletType.iguana,
        newPassword: _newPasswordController.text,
      );

      widget.onImport(
        name: _nameController.text,
        password: _newPasswordController.text,
        walletConfig: walletConfig,
        legacyData: _legacyData,
      );
    } catch (e) {
      setState(() {
        _commonError = 'Failed to import wallet';
        _inProgress = false;
      });
      log(
        'Failed to import legacy wallet: $e',
        path: 'LegacyWalletImport._importWallet',
        isError: true,
      );
    }
  }

  String? _validateWalletName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Wallet name is required';
    }

    final walletsRepository = RepositoryProvider.of<WalletsRepository>(context);
    final existingWallet = walletsRepository.wallets
        ?.where((w) => w.name == name.trim())
        .firstOrNull;

    if (existingWallet != null) {
      return LocaleKeys.walletCreationExistNameError.tr();
    }

    return null;
  }

  String? _validateLegacyPassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  String? _validateNewPassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return LocaleKeys.walletCreationFormatPasswordError.tr();
    }
    return null;
  }

  String? _validateConfirmPassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password != _newPasswordController.text) {
      return LocaleKeys.walletCreationConfirmPasswordError.tr();
    }
    return null;
  }
}
