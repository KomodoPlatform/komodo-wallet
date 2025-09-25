import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';
import 'package:web_dex/shared/ui/ui_gradient_icon.dart';
import 'package:web_dex/bloc/wallet_file_import/wallet_file_import_bloc.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/widgets/disclaimer/eula_tos_checkboxes.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';
import 'package:web_dex/shared/widgets/quick_login_switch.dart';
import 'package:web_dex/views/wallets_manager/widgets/custom_seed_checkbox.dart';
import 'package:web_dex/views/wallets_manager/widgets/hdwallet_mode_switch.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_rename_dialog.dart';

class WalletFileData {
  const WalletFileData({required this.name, this.text, this.bytes})
    : assert(text != null || bytes != null);

  final String name;
  final String? text;
  final Uint8List? bytes;

  bool get hasText => text != null && text!.isNotEmpty;
  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
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
    required bool rememberMe,
  })
  onImport;
  final void Function() onCancel;

  @override
  State<WalletImportByFile> createState() => _WalletImportByFileState();
}

class _WalletImportByFileState extends State<WalletImportByFile> {
  final TextEditingController _filePasswordController = TextEditingController(
    text: '',
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscured = true;
  bool _isHdMode = false;
  bool _eulaAndTosChecked = false;
  bool _rememberMe = false;
  bool _allowCustomSeed = false;

  String? _filePasswordError;
  String? _commonError;

  // Intentionally do not check wallet name here, because it is done on button
  // click and a dialog is shown to rename the wallet if there are issues.
  bool get _isButtonEnabled => _eulaAndTosChecked;

  @override
  Widget build(BuildContext context) {
    return ScreenshotSensitive(
      child: BlocProvider(
        create: (context) =>
            WalletFileImportBloc(sdk: context.read<KomodoDefiSdk>()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleKeys.walletImportByFileTitle.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text(
              LocaleKeys.walletImportByFileDescription.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              LocaleKeys.walletImportLegacySupportNote.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              LocaleKeys.walletImportFileFormatsHint.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 20),
            BlocListener<WalletFileImportBloc, WalletFileImportState>(
              listener: (context, state) {
                if (state.status == WalletFileImportStatus.failure) {
                  setState(() {
                    _filePasswordError = null;
                    _commonError = null;
                    switch (state.error) {
                      case WalletFileImportFailureType.incorrectPassword:
                        _filePasswordError = LocaleKeys.incorrectPassword.tr();
                        break;
                      case WalletFileImportFailureType.invalidSeed:
                        _commonError = LocaleKeys.walletCreationBip39SeedError
                            .tr();
                        break;
                      case WalletFileImportFailureType.invalidFile:
                      case null:
                        _commonError = LocaleKeys.somethingWrong.tr();
                        break;
                    }
                  });
                  _formKey.currentState?.validate();
                }

                if (state.status == WalletFileImportStatus.success &&
                    state.walletConfig != null) {
                  final walletConfig = state.walletConfig!;
                  setState(() {
                    _filePasswordError = null;
                    _commonError = null;
                  });
                  _formKey.currentState?.validate();

                  String name = widget.fileData.name.replaceFirst(
                    RegExp(r'\.[^.]+$'),
                    '',
                  );
                  final walletsRepository =
                      RepositoryProvider.of<WalletsRepository>(context);

                  String? validationError = walletsRepository
                      .validateWalletName(name);
                  if (validationError != null) {
                    if (!mounted) return;
                    walletRenameDialog(context, initialName: name).then((
                      newName,
                    ) async {
                      if (newName == null) {
                        return;
                      }
                      final postValidation = walletsRepository
                          .validateWalletName(newName);
                      if (postValidation != null) {
                        return;
                      }
                      final trimmed = newName.trim();
                      TextInput.finishAutofillContext(shouldSave: false);
                      widget.onImport(
                        name: trimmed,
                        password: _filePasswordController.text,
                        walletConfig: walletConfig,
                        rememberMe: _rememberMe,
                      );
                    });
                    return;
                  }

                  TextInput.finishAutofillContext(shouldSave: false);
                  widget.onImport(
                    name: name,
                    password: _filePasswordController.text,
                    walletConfig: walletConfig,
                    rememberMe: _rememberMe,
                  );
                }
              },
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      UiTextFormField(
                        key: const Key('file-password-field'),
                        controller: _filePasswordController,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableInteractiveSelection: true,
                        obscureText: _isObscured,
                        maxLength: passwordMaxLength,
                        counterText: '',
                        autofillHints: const [AutofillHints.password],
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
                      Row(
                        children: [
                          const UiGradientIcon(icon: Icons.folder, size: 32),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.fileData.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_commonError != null)
                        Align(
                          alignment: const Alignment(-1, 0),
                          child: SelectableText(
                            _commonError ?? '',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
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
                      const SizedBox(height: 20),
                      QuickLoginSwitch(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value);
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _filePasswordController.dispose();

    super.dispose();
  }

  // Using Bloc to handle import logic

  Future<void> _onImport() async {
    final String password = _filePasswordController.text;
    context.read<WalletFileImportBloc>().add(
      WalletFileImportSubmitted(
        password: password,
        isHdMode: _isHdMode,
        allowCustomSeed: _allowCustomSeed,
        fileText: widget.fileData.text,
        fileBytes: widget.fileData.bytes,
      ),
    );
  }
}
