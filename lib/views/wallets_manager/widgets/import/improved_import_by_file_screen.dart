import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';
import 'package:web_dex/views/wallets_manager/widgets/creation_password_fields.dart';
import 'package:web_dex/views/wallets_manager/widgets/hdwallet_mode_switch.dart';
import 'package:web_dex/views/wallets_manager/widgets/import/file_drop_zone.dart';
import 'package:web_dex/views/wallets_manager/widgets/import/legacy_seed_info_dialog.dart';

class ImprovedImportByFileScreen extends StatefulWidget {
  const ImprovedImportByFileScreen({
    required this.onImport,
    required this.onCancel,
    super.key,
  });

  final void Function({
    required String name,
    required String password,
    required WalletConfig walletConfig,
  })
  onImport;
  final VoidCallback onCancel;

  @override
  State<ImprovedImportByFileScreen> createState() =>
      _ImprovedImportByFileScreenState();
}

class _ImprovedImportByFileScreenState
    extends State<ImprovedImportByFileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _filePasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _fileData;
  bool _isHdMode = true;
  bool _isLegacySeed = false;
  bool _inProgress = false;
  String? _commonError;

  bool get _canImport {
    return _nameController.text.trim().isNotEmpty &&
        _fileData != null &&
        _filePasswordController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        !_inProgress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _filePasswordController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onImport() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_fileData == null) {
      _showError(LocaleKeys.importFileNotSelected.tr());
      return;
    }

    setState(() {
      _inProgress = true;
      _commonError = null;
    });

    try {
      final EncryptionTool encryptionTool = EncryptionTool();
      final String? decryptedFileData = await encryptionTool.decryptData(
        _filePasswordController.text,
        _fileData!,
      );

      if (decryptedFileData == null) {
        setState(() {
          _commonError = LocaleKeys.incorrectPassword.tr();
          _inProgress = false;
        });
        return;
      }

      final WalletConfig walletConfig = WalletConfig.fromJson(
        json.decode(decryptedFileData),
      );
      walletConfig.type = _isHdMode ? WalletType.hdwallet : WalletType.iguana;

      final String? decryptedSeed = await encryptionTool.decryptData(
        _filePasswordController.text,
        walletConfig.seedPhrase,
      );

      if (decryptedSeed == null) {
        setState(() {
          _commonError = LocaleKeys.incorrectPassword.tr();
          _inProgress = false;
        });
        return;
      }

      // Validate BIP39 if not legacy
      if (!_isLegacySeed) {
        final sdk = context.read<KomodoDefiSdk>();
        if (!sdk.mnemonicValidator.validateBip39(decryptedSeed)) {
          setState(() {
            _commonError = LocaleKeys.walletCreationBip39SeedError.tr();
            _inProgress = false;
          });
          return;
        }
      }

      walletConfig.seedPhrase = decryptedSeed;
      walletConfig.activatedCoins = enabledByDefaultCoins;
      walletConfig.hasBackup = true;

      // Check wallet name uniqueness
      final repo = context.read<WalletsRepository>();
      final uniquenessError = await repo.validateWalletNameUniqueness(
        _nameController.text.trim(),
      );

      if (uniquenessError != null) {
        setState(() {
          _commonError = uniquenessError;
          _inProgress = false;
        });
        return;
      }

      widget.onImport(
        name: _nameController.text.trim(),
        password: _passwordController.text,
        walletConfig: walletConfig,
      );
    } catch (e) {
      setState(() {
        _commonError = LocaleKeys.importFileError.tr();
        _inProgress = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScreenshotSensitive(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.importBySeedFileTitle.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                key: const Key('import-by-file-close'),
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.importBySeedFileDescription.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWalletNameField(),
                    const SizedBox(height: 20),
                    FileDropZone(
                      onFileSelected: (fileName, fileContent) {
                        setState(() {
                          _fileData = fileContent;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    UiTextFormField(
                      key: const Key('file-password-field'),
                      controller: _filePasswordController,
                      obscureText: true,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      hintText: LocaleKeys.importFilePasswordHint.tr(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return LocaleKeys.fieldRequired.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      LocaleKeys.importCreateNewPasswordLabel.tr(),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    CreationPasswordFields(
                      passwordController: _passwordController,
                    ),
                    const SizedBox(height: 20),
                    HDWalletModeSwitch(
                      value: _isHdMode,
                      onChanged: (value) {
                        setState(() => _isHdMode = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLegacySeedCheckbox(),
                    if (_commonError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _commonError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    UiPrimaryButton(
                      key: const Key('import-by-file-submit'),
                      text: _inProgress
                          ? LocaleKeys.pleaseWait.tr()
                          : LocaleKeys.import.tr(),
                      onPressed: _canImport ? _onImport : null,
                    ),
                    const SizedBox(height: 12),
                    UiUnderlineTextButton(
                      key: const Key('import-by-file-cancel'),
                      text: LocaleKeys.cancel.tr(),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletNameField() {
    final walletsRepository = context.read<WalletsRepository>();

    return UiTextFormField(
      key: const Key('import-file-wallet-name'),
      controller: _nameController,
      autofocus: true,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      validator: (String? value) =>
          walletsRepository.validateWalletName(value ?? ''),
      inputFormatters: [LengthLimitingTextInputFormatter(40)],
      hintText: LocaleKeys.importWalletNameHint.tr(),
    );
  }

  Widget _buildLegacySeedCheckbox() {
    final theme = Theme.of(context);

    return Row(
      children: [
        Checkbox(
          key: const Key('legacy-seed-checkbox'),
          value: _isLegacySeed,
          onChanged: (value) {
            setState(() => _isLegacySeed = value ?? false);
          },
        ),
        Expanded(
          child: Text(
            LocaleKeys.legacySeedCheckboxLabel.tr(),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        IconButton(
          icon: Icon(Icons.info_outline, color: theme.colorScheme.primary),
          onPressed: () => showLegacySeedInfoDialog(context),
        ),
      ],
    );
  }
}
