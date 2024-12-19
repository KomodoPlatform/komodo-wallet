import 'package:bip39/bip39.dart' as bip39;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/disclaimer/eula_tos_checkboxes.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';
import 'package:web_dex/views/wallets_manager/widgets/creation_password_fields.dart';
import 'package:web_dex/views/wallets_manager/widgets/custom_seed_dialog.dart';
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

enum WalletSimpleImportSteps {
  nameAndSeed,
  password,
}

class _WalletImportWrapperState extends State<WalletSimpleImport> {
  WalletSimpleImportSteps _step = WalletSimpleImportSteps.nameAndSeed;
  final TextEditingController _nameController = TextEditingController(text: '');
  final TextEditingController _seedController = TextEditingController(text: '');
  final TextEditingController _passwordController =
      TextEditingController(text: '');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSeedHidden = true;
  bool _eulaAndTosChecked = false;
  bool _inProgress = false;
  bool? _allowCustomSeed;
  bool _isHdMode = true;

  bool get _isButtonEnabled {
    return _eulaAndTosChecked && !_inProgress;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableText(
          _step == WalletSimpleImportSteps.nameAndSeed
              ? LocaleKeys.walletImportTitle.tr()
              : LocaleKeys.walletImportCreatePasswordTitle
                  .tr(args: [_nameController.text]),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildFields(),
              const SizedBox(height: 32),
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
    return UiCheckbox(
      checkboxKey: const Key('checkbox-custom-seed'),
      value: _allowCustomSeed!,
      text: LocaleKeys.allowCustomFee.tr(),
      onChanged: (bool? data) async {
        if (data == null) return;
        if (!_allowCustomSeed!) {
          final bool confirmed = await customSeedDialog(context);
          if (!confirmed) return;
        }

        setState(() {
          _allowCustomSeed = !_allowCustomSeed!;
        });

        if (_seedController.text.isNotEmpty &&
            _nameController.text.isNotEmpty) {
          _formKey.currentState!.validate();
        }
      },
    );
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
      children: [
        _buildNameField(),
        const SizedBox(height: 16),
        _buildSeedField(),
        HDWalletModeSwitch(
          value: _isHdMode,
          onChanged: (value) {
            setState(() => _isHdMode = value);
          },
        ),
        if (_allowCustomSeed != null) ...[
          const SizedBox(height: 15),
          _buildCheckBoxCustomSeed(),
        ],
        const SizedBox(height: 25),
        UiDivider(text: LocaleKeys.or.tr()),
        const SizedBox(height: 20),
        _buildImportFileButton(),
        const SizedBox(height: 22),
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
        name: _nameController.text,
        password: _passwordController.text,
        walletConfig: config,
      );
    });
  }

  String? _validateSeed(String? seed) {
    if (seed == null || seed.isEmpty) {
      return LocaleKeys.walletCreationEmptySeedError.tr();
    } else if ((_allowCustomSeed != true) && !bip39.validateMnemonic(seed)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _allowCustomSeed = false;
          });
        }
      });
      return LocaleKeys.walletCreationBip39SeedError.tr();
    }
    return null;
  }
}
