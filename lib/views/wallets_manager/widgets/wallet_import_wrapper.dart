import 'package:flutter/material.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/views/wallets_manager/widgets/import/import_method_selection.dart';
import 'package:web_dex/views/wallets_manager/widgets/import/import_by_phrase_screen.dart';
import 'package:web_dex/views/wallets_manager/widgets/import/improved_import_by_file_screen.dart';
import 'package:web_dex/views/wallets_manager/widgets/creation_password_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/widgets/quick_login_switch.dart';

class WalletImportWrapper extends StatefulWidget {
  const WalletImportWrapper({
    super.key,
    required this.onImport,
    required this.onCancel,
  });

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

enum ImportStep { methodSelection, phraseEntry, phrasePassword, fileImport }

class _WalletImportWrapperState extends State<WalletImportWrapper> {
  ImportStep _currentStep = ImportStep.methodSelection;
  String? _pendingWalletName;
  String? _pendingSeedPhrase;
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _inProgress = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case ImportStep.methodSelection:
        return ImportMethodSelection(onMethodSelected: _onMethodSelected);
      case ImportStep.phraseEntry:
        return ImportByPhraseScreen(
          onContinue: _onPhraseEntered,
          onCancel: _onBackToMethodSelection,
        );
      case ImportStep.phrasePassword:
        return _buildPasswordStep();
      case ImportStep.fileImport:
        return ImprovedImportByFileScreen(
          onImport:
              ({
                required String name,
                required String password,
                required WalletConfig walletConfig,
              }) {
                widget.onImport(
                  name: name,
                  password: password,
                  walletConfig: walletConfig,
                  rememberMe: false,
                );
              },
          onCancel: _onBackToMethodSelection,
        );
    }
  }

  void _onMethodSelected(ImportMethod method) {
    setState(() {
      if (method == ImportMethod.secretPhrase) {
        _currentStep = ImportStep.phraseEntry;
      } else {
        _currentStep = ImportStep.fileImport;
      }
    });
  }

  void _onPhraseEntered({
    required String walletName,
    required String seedPhrase,
  }) {
    setState(() {
      _pendingWalletName = walletName;
      _pendingSeedPhrase = seedPhrase;
      _currentStep = ImportStep.phrasePassword;
    });
  }

  void _onBackToMethodSelection() {
    setState(() {
      _currentStep = ImportStep.methodSelection;
      _pendingWalletName = null;
      _pendingSeedPhrase = null;
      _passwordController.clear();
    });
  }

  void _onBackToPhraseEntry() {
    setState(() {
      _currentStep = ImportStep.phraseEntry;
      _passwordController.clear();
    });
  }

  void _onPasswordConfirmed() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final walletConfig = WalletConfig(
      type: WalletType.hdwallet,
      activatedCoins: enabledByDefaultCoins,
      hasBackup: true,
      seedPhrase: _pendingSeedPhrase!,
    );

    setState(() => _inProgress = true);

    widget.onImport(
      name: _pendingWalletName!,
      password: _passwordController.text,
      walletConfig: walletConfig,
      rememberMe: _rememberMe,
    );
  }

  Widget _buildPasswordStep() {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                LocaleKeys.walletImportCreatePasswordTitle.tr(
                  args: [_pendingWalletName ?? ''],
                ),
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              key: const Key('import-password-close'),
              icon: const Icon(Icons.close),
              onPressed: widget.onCancel,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Flexible(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            LocaleKeys.walletImportByFileDescription.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CreationPasswordFields(
                    passwordController: _passwordController,
                    onFieldSubmitted: (_) {
                      if (!_inProgress) {
                        _onPasswordConfirmed();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  QuickLoginSwitch(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  UiPrimaryButton(
                    key: const Key('import-password-continue'),
                    text: _inProgress
                        ? LocaleKeys.pleaseWait.tr()
                        : LocaleKeys.import.tr(),
                    onPressed: _inProgress ? null : _onPasswordConfirmed,
                  ),
                  const SizedBox(height: 12),
                  UiUnderlineTextButton(
                    key: const Key('import-password-back'),
                    text: LocaleKeys.back.tr(),
                    onPressed: _onBackToPhraseEntry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
