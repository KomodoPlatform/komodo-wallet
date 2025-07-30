import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart'
    show MnemonicFailedReason;
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/disclaimer/eula_tos_checkboxes.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';
import 'package:web_dex/views/wallets_manager/widgets/creation_password_fields.dart';
import 'package:web_dex/views/wallets_manager/widgets/custom_seed_checkbox.dart';
import 'package:web_dex/views/wallets_manager/widgets/hdwallet_mode_switch.dart';

class WalletSimpleImport extends StatefulWidget {
  const WalletSimpleImport({
    required this.onImport,
    required this.onUploadFiles,
    required this.onCancel,
    super.key,
  });

  final void Function({
    required String name,
    required String password,
    required WalletConfig walletConfig,
  }) onImport;

  final void Function() onCancel;

  final void Function({required String fileName, required String fileData})
      onUploadFiles;

  @override
  State<WalletSimpleImport> createState() => _WalletImportWrapperState();
}

enum WalletSimpleImportSteps { nameAndSeed, password }

class _WalletImportWrapperState extends State<WalletSimpleImport> {
  WalletSimpleImportSteps _step = WalletSimpleImportSteps.nameAndSeed;
  final TextEditingController _nameController = TextEditingController(text: '');
  final TextEditingController _seedController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(
    text: '',
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSeedHidden = true;
  bool _eulaAndTosChecked = false;
  bool _inProgress = false;
  bool _allowCustomSeed = false;
  bool _isHdMode = false;

  bool get _isButtonEnabled {
    final isFormValid = _refreshFormValidationState();

    return _eulaAndTosChecked && !_inProgress && isFormValid;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (!state.isLoading) {
          setState(() => _inProgress = false);
        }

        if (state.isError) {
          final theme = Theme.of(context);
          final message =
              state.authError?.message ?? LocaleKeys.somethingWrong.tr();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              backgroundColor: theme.colorScheme.errorContainer,
            ),
          );
        }
      },
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              _step == WalletSimpleImportSteps.nameAndSeed
                  ? LocaleKeys.walletImportTitle.tr()
                  : LocaleKeys.walletImportCreatePasswordTitle.tr(
                      args: [_nameController.text.trim()],
                    ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildFields(),
                  const SizedBox(height: 20),
                  UiPrimaryButton(
                    key: const Key('confirm-seed-button'),
                    text: _inProgress
                        ? '${LocaleKeys.pleaseWait.tr()}...'
                        : LocaleKeys.import.tr(),
                    height: 50,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: _isButtonEnabled ? _onImport : null,
                  ),
                  const SizedBox(height: 20),
                  UiUnderlineTextButton(
                    onPressed: _onCancel,
                    text: _step == WalletSimpleImportSteps.nameAndSeed
                        ? LocaleKeys.cancel.tr()
                        : LocaleKeys.back.tr(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seedController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildCheckBoxCustomSeed() {
    return CustomSeedCheckbox(
      value: _allowCustomSeed,
      onChanged: (value) {
        setState(() {
          _allowCustomSeed = value;
        });

        _refreshFormValidationState();
      },
    );
  }

  bool _refreshFormValidationState() {
    final nameHasValue = _nameController.text.isNotEmpty;
    final seedHasValue = _seedController.text.isNotEmpty;

    if (seedHasValue && nameHasValue) {
      return _formKey.currentState!.validate();
    }

    return false;
  }

  Widget _buildFields() {
    switch (_step) {
      case WalletSimpleImportSteps.nameAndSeed:
        return _buildNameAndSeed();
      case WalletSimpleImportSteps.password:
        return CreationPasswordFields(
          passwordController: _passwordController,
          onFieldSubmitted: !_isButtonEnabled
              ? null
              : (text) {
                  _onImport();
                },
        );
    }
  }

  Widget _buildImportFileButton() {
    return UploadButton(
      buttonText: LocaleKeys.walletCreationUploadFile.tr(),
      uploadFile: () async {
        await FileLoader.fromPlatform().upload(
          onUpload: (fileName, fileData) => widget.onUploadFiles(
            fileData: fileData ?? '',
            fileName: fileName,
          ),
          onError: (String error) {
            log(
              error,
              path:
                  'wallet_simple_import => _buildImportFileButton => onErrorUploadFiles',
              isError: true,
            );
          },
          fileType: LoadFileType.text,
        );
      },
    );
  }

  Widget _buildNameAndSeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNameField(),
        const SizedBox(height: 16),
        _buildSeedField(),
        const SizedBox(height: 16),
        HDWalletModeSwitch(
          value: _isHdMode,
          onChanged: (value) {
            setState(() {
              _isHdMode = value;
              _allowCustomSeed = false;
            });

            _refreshFormValidationState();
          },
        ),
        const SizedBox(height: 20),
        UiDivider(text: LocaleKeys.seedOr.tr()),
        const SizedBox(height: 20),
        _buildImportFileButton(),
        const SizedBox(height: 15),
        if (!_isHdMode) _buildCheckBoxCustomSeed(),
        const SizedBox(height: 15),
        EulaTosCheckboxes(
          key: const Key('import-wallet-eula-checks'),
          isChecked: _eulaAndTosChecked,
          onCheck: (isChecked) {
            setState(() {
              _eulaAndTosChecked = isChecked;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNameField() {
    final walletsRepository = RepositoryProvider.of<WalletsRepository>(context);
    return UiTextFormField(
      key: const Key('name-wallet-field'),
      controller: _nameController,
      autofocus: true,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username],
      validator: (String? name) =>
          _inProgress ? null : walletsRepository.validateWalletName(name ?? ''),
      inputFormatters: [LengthLimitingTextInputFormatter(40)],
      hintText: LocaleKeys.walletCreationNameHint.tr(),
    );
  }

  Widget _buildSeedField() {
    return UiTextFormField(
      key: const Key('import-seed-field'),
      controller: _seedController,
      autofocus: true,
      validator: _validateSeed,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      obscureText: _isSeedHidden,
      maxLines: _isSeedHidden ? 1 : null,
      errorMaxLines: 4,
      style: Theme.of(context).textTheme.bodyMedium,
      hintText: LocaleKeys.importSeedEnterSeedPhraseHint.tr(),
      suffixIcon: PasswordVisibilityControl(
        onVisibilityChange: (bool isObscured) {
          setState(() {
            _isSeedHidden = isObscured;
          });
        },
      ),
      onFieldSubmitted: !_isButtonEnabled
          ? null
          : (text) {
              _onImport();
            },
    );
  }

  void _onCancel() {
    if (_step == WalletSimpleImportSteps.password) {
      setState(() {
        _step = WalletSimpleImportSteps.nameAndSeed;
      });
      return;
    }
    widget.onCancel();
  }

  void _onImport() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_step == WalletSimpleImportSteps.nameAndSeed) {
      setState(() {
        _step = WalletSimpleImportSteps.password;
      });
      return;
    }

    final WalletConfig config = WalletConfig(
      type: _isHdMode ? WalletType.hdwallet : WalletType.iguana,
      activatedCoins: enabledByDefaultCoins,
      hasBackup: true,
      seedPhrase: _seedController.text,
    );

    setState(() => _inProgress = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onImport(
        name: _nameController.text.trim(),
        password: _passwordController.text,
        walletConfig: config,
      );
    });
  }

  String? _validateSeed(String? seed) {
    if (_allowCustomSeed) {
      return null;
    }

    final maybeFailedReason =
        context.read<KomodoDefiSdk>().mnemonicValidator.validateMnemonic(
              seed ?? '',
              minWordCount: 12,
              maxWordCount: 24,
              isHd: _isHdMode,
              allowCustomSeed: _allowCustomSeed,
            );

    if (maybeFailedReason == null) {
      return null;
    }

    return switch (maybeFailedReason) {
      MnemonicFailedReason.empty =>
        LocaleKeys.walletCreationEmptySeedError.tr(),
      MnemonicFailedReason.customNotSupportedForHd => _isHdMode
          ? LocaleKeys.walletCreationHdBip39SeedError.tr()
          : LocaleKeys.walletCreationBip39SeedError.tr(),
      MnemonicFailedReason.customNotAllowed =>
        LocaleKeys.customSeedWarningText.tr(),
      MnemonicFailedReason.invalidLength =>
        // TODO: Add this string has placeholders for min/max counts, which we
        // specify as "12" and "24"
        // LocaleKeys.seedPhraseCheckingEnterWord.tr(args: ['12', '24']),
        _isHdMode
            ? LocaleKeys.walletCreationHdBip39SeedError.tr()
            : LocaleKeys.walletCreationBip39SeedError.tr(),
    };
  }
}
