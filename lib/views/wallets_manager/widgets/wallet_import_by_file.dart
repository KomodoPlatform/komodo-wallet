import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/ui/ui_gradient_icon.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';
import 'package:web_dex/shared/widgets/disclaimer/eula_tos_checkboxes.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';
import 'package:web_dex/views/wallets_manager/widgets/custom_seed_checkbox.dart';
import 'package:web_dex/views/wallets_manager/widgets/hdwallet_mode_switch.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_rename_dialog.dart';

class WalletFileData {
  const WalletFileData({required this.content, required this.name});
  final String content;
  final String name;
}

class WalletImportByFile extends StatefulWidget {
  const WalletImportByFile({
    super.key,
    required this.fileData,
    required this.onImport,
    required this.onCancel,
  });
  final WalletFileData fileData;

  final void Function({
    required String name,
    required String password,
    required WalletConfig walletConfig,
  }) onImport;
  final void Function() onCancel;

  @override
  State<WalletImportByFile> createState() => _WalletImportByFileState();
}

class _WalletImportByFileState extends State<WalletImportByFile> {
  final TextEditingController _filePasswordController =
      TextEditingController(text: '');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscured = true;
  bool _isHdMode = false;
  bool _eulaAndTosChecked = false;
  bool _allowCustomSeed = false;

  String? _filePasswordError;
  String? _commonError;

  bool get _isValidData {
    return _filePasswordError == null;
  }

  bool get _isButtonEnabled => _eulaAndTosChecked;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.walletImportByFileTitle.tr(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 20),
        Text(LocaleKeys.walletImportByFileDescription.tr(),
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UiTextFormField(
                key: const Key('file-password-field'),
                controller: _filePasswordController,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableInteractiveSelection: true,
                obscureText: _isObscured,
                validator: (_) {
                  return _filePasswordError;
                },
                errorMaxLines: 6,
                hintText: LocaleKeys.walletCreationPasswordHint.tr(),
                suffixIcon: PasswordVisibilityControl(
                  onVisibilityChange: (bool isPasswordObscured) {
                    setState(() {
                      _isObscured = isPasswordObscured;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
              Row(children: [
                const UiGradientIcon(
                  icon: Icons.folder,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  widget.fileData.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
              if (_commonError != null)
                Align(
                  alignment: const Alignment(-1, 0),
                  child: SelectableText(
                    _commonError ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 30),
              HDWalletModeSwitch(
                value: _isHdMode,
                onChanged: (value) {
                  setState(() => _isHdMode = value);
                },
              ),
              const SizedBox(height: 15),
              if (!_isHdMode)
                CustomSeedCheckbox(
                  value: _allowCustomSeed,
                  onChanged: (value) {
                    setState(() {
                      _allowCustomSeed = value;
                    });
                  },
                ),
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
              const SizedBox(height: 30),
              UiPrimaryButton(
                key: const Key('confirm-password-button'),
                height: 50,
                text: LocaleKeys.import.tr(),
                onPressed: _isButtonEnabled ? _onImport : null,
              ),
              const SizedBox(height: 20),
              UiUnderlineTextButton(
                onPressed: widget.onCancel,
                text: LocaleKeys.back.tr(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _filePasswordController.dispose();

    super.dispose();
  }

  // TODO? Investigate if using this instead of a getter may have limitations
  // or issues with multi-instance support
  late final KomodoDefiSdk _sdk = context.read<KomodoDefiSdk>();

  Future<void> _onImport() async {
    final EncryptionTool encryptionTool = EncryptionTool();
    final String? fileData = await encryptionTool.decryptData(
      _filePasswordController.text,
      widget.fileData.content,
    );
    if (fileData == null) {
      setState(() {
        _filePasswordError = LocaleKeys.incorrectPassword.tr();
      });
      _formKey.currentState?.validate();
      return;
    } else {
      setState(() {
        _filePasswordError = null;
      });
    }
    _formKey.currentState?.validate();
    try {
      final WalletConfig walletConfig =
          WalletConfig.fromJson(json.decode(fileData));
      walletConfig.type = _isHdMode ? WalletType.hdwallet : WalletType.iguana;

      final String? decryptedSeed = await encryptionTool.decryptData(
          _filePasswordController.text, walletConfig.seedPhrase);
      if (decryptedSeed == null) return;
      if (!_isValidData) return;

      if ((_isHdMode || !_allowCustomSeed) &&
          !_sdk.mnemonicValidator.validateBip39(decryptedSeed)) {
        setState(() {
          _commonError = LocaleKeys.walletCreationBip39SeedError.tr();
        });
        return;
      }

      walletConfig.seedPhrase = decryptedSeed;
      String name = widget.fileData.name.split('.').first;
      // ignore: use_build_context_synchronously
      final walletsBloc = RepositoryProvider.of<WalletsRepository>(context);
      final bool isNameExisted =
          walletsBloc.wallets!.firstWhereOrNull((w) => w.name == name) != null;
      if (isNameExisted) {
        setState(() {
          _commonError = LocaleKeys.walletCreationExistNameError.tr();
        });
        return;
      }
      String? validationError = walletsBloc.validateWalletName(name);
      if (validationError != null) {
        // ignore: use_build_context_synchronously
        final newName = await walletRenameDialog(
          context,
          initialName: name,
        );
        if (newName == null) {
          return;
        }
        name = newName;
      }
      widget.onImport(
        name: name,
        password: _filePasswordController.text,
        walletConfig: walletConfig,
      );
    } catch (_) {
      setState(() {
        _commonError = LocaleKeys.somethingWrong.tr();
      });
    }
  }
}
