import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';

// TODO: refactor this widget, and other seed viewing/backup related widgets
// to use a dedicated bloc for seed access attempts (view and download)
class PasswordDialogContent extends StatefulWidget {
  const PasswordDialogContent({
    required this.onSuccess,
    required this.onCancel,
    super.key,
    this.wallet,
  });

  final void Function(String) onSuccess;

  final VoidCallback onCancel;
  final Wallet? wallet;

  @override
  State<PasswordDialogContent> createState() => _PasswordDialogContentState();
}

class _PasswordDialogContentState extends State<PasswordDialogContent> {
  bool _isObscured = true;
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _inProgress = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: isMobile
          ? const BoxConstraints(maxWidth: 362)
          : const BoxConstraints(maxHeight: 320, maxWidth: 362),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 46),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.confirmationForShowingSeedPhraseTitle.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiTextFormField(
                  key: const Key('confirmation-showing-seed-phrase'),
                  controller: _passwordController,
                  autofocus: true,
                  autocorrect: false,
                  obscureText: _isObscured,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  errorMaxLines: 6,
                  errorText: _error,
                  hintText: LocaleKeys.enterThePassword.tr(),
                  suffixIcon: PasswordVisibilityControl(
                    onVisibilityChange: (bool isPasswordObscured) {
                      setState(() {
                        _isObscured = isPasswordObscured;
                      });
                    },
                  ),
                  onFieldSubmitted: (text) => _onContinue(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: UiPrimaryButton(
                    onPressed: _inProgress ? null : _onContinue,
                    text: LocaleKeys.continueText.tr(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: UiUnderlineTextButton(
                    text: LocaleKeys.cancel.tr(),
                    onPressed: widget.onCancel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onContinue() async {
    final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
    if (currentWallet == null) return;
    final String password = _passwordController.text;

    setState(() => _inProgress = true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sdk = RepositoryProvider.of<KomodoDefiSdk>(context);
      try {
        final seed = await sdk.auth.getMnemonicPlainText(password);
        if (seed.plaintextMnemonic?.isEmpty ?? true) {
          _setInvalidPasswordState();
          return;
        }
      } catch (_) {
        _setInvalidPasswordState();
        return;
      }

      widget.onSuccess(password);

      if (mounted) setState(() => _inProgress = false);
    });
  }

  void _setInvalidPasswordState() {
    setState(() {
      _error = LocaleKeys.incorrectPassword.tr();
      _inProgress = false;
    });
  }
}
