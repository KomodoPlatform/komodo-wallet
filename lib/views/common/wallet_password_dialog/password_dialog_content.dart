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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 24),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hidden username field for password manager context
                  Visibility(
                    visible: false,
                    maintainSize: false,
                    maintainAnimation: false,
                    maintainState: false,
                    child: UiTextFormField(
                      initialValue: widget.wallet?.name ?? '',
                      autofillHints: const [AutofillHints.username],
                      readOnly: true,
                    ),
                  ),
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
                    autofillHints: const [AutofillHints.password],
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
                      text: _inProgress
                          ? LocaleKeys.faucetLoadingTitle.tr()
                          : LocaleKeys.continueText.tr(),
                      prefix: _inProgress
                          ? const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : null,
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

      if (mounted) {
        widget.onSuccess(password);
        setState(() => _inProgress = false);
      }
    });
  }

  void _setInvalidPasswordState() {
    if (mounted) {
      setState(() {
        _error = LocaleKeys.incorrectPassword.tr();
        _inProgress = false;
      });
    }
  }
}

/// Enhanced password dialog that supports loading state for various operations.
///
/// This dialog validates the password and then calls [onPasswordValidated] with the
/// password. It shows a loading indicator during the operation and only closes when
/// the operation is complete or fails.
class PasswordDialogContentWithLoading extends StatefulWidget {
  const PasswordDialogContentWithLoading({
    required this.onPasswordValidated,
    required this.onComplete,
    required this.onCancel,
    super.key,
    this.wallet,
    this.loadingTitle,
    this.loadingMessage,
    this.operationFailedMessage,
    this.passwordFieldKey = 'confirmation-showing-operation',
  });

  /// Called after password validation succeeds. Should return true if operation succeeds.
  final Future<bool> Function(String password) onPasswordValidated;

  /// Called when the entire operation (password + custom operation) completes.
  final void Function(bool success) onComplete;

  final VoidCallback onCancel;
  final Wallet? wallet;

  /// Title shown during the loading/operation phase.
  /// Defaults to fetching private keys title for backward compatibility.
  final String? loadingTitle;

  /// Message shown during the loading/operation phase.
  /// Defaults to fetching private keys message for backward compatibility.
  final String? loadingMessage;

  /// Error message shown if the operation fails.
  /// Defaults to private key retrieval failed for backward compatibility.
  final String? operationFailedMessage;

  /// Key used for the password text field for testing purposes.
  final String passwordFieldKey;

  @override
  State<PasswordDialogContentWithLoading> createState() =>
      _PasswordDialogContentWithLoadingState();
}

class _PasswordDialogContentWithLoadingState
    extends State<PasswordDialogContentWithLoading> {
  bool _isObscured = true;
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _inProgress = false;
  bool _fetchingPrivateKeys = false;

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
            _fetchingPrivateKeys
                ? (widget.loadingTitle ??
                      LocaleKeys.fetchingPrivateKeysTitle.tr())
                : LocaleKeys.confirmationForShowingSeedPhraseTitle.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (_fetchingPrivateKeys) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              widget.loadingMessage ??
                  LocaleKeys.fetchingPrivateKeysMessage.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.only(top: 24),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hidden username field for password manager context
                    Visibility(
                      visible: false,
                      maintainSize: false,
                      maintainAnimation: false,
                      maintainState: false,
                      child: UiTextFormField(
                        initialValue: widget.wallet?.name ?? '',
                        autofillHints: const [AutofillHints.username],
                        readOnly: true,
                      ),
                    ),
                    UiTextFormField(
                      key: Key(widget.passwordFieldKey),
                      controller: _passwordController,
                      autofocus: true,
                      autocorrect: false,
                      obscureText: _isObscured,
                      inputFormatters: [LengthLimitingTextInputFormatter(40)],
                      errorMaxLines: 6,
                      errorText: _error,
                      hintText: LocaleKeys.enterThePassword.tr(),
                      autofillHints: const [AutofillHints.password],
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
                        text: _inProgress
                            ? LocaleKeys.faucetLoadingTitle.tr()
                            : LocaleKeys.continueText.tr(),
                        prefix: _inProgress
                            ? const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: UiUnderlineTextButton(
                        text: LocaleKeys.cancel.tr(),
                        onPressed: _fetchingPrivateKeys
                            ? null
                            : widget.onCancel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onContinue() async {
    final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
    if (currentWallet == null) return;
    final String password = _passwordController.text;

    setState(() => _inProgress = true);

    // First, validate the password
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

      // Password is valid, now fetch private keys
      if (mounted) {
        setState(() {
          _inProgress = false;
          _fetchingPrivateKeys = true;
          _error = null;
        });
      }

      try {
        final success = await widget.onPasswordValidated(password);
        if (mounted) {
          widget.onComplete(success);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _fetchingPrivateKeys = false;
            _error =
                widget.operationFailedMessage ??
                LocaleKeys.privateKeyRetrievalFailed.tr();
          });
          widget.onComplete(false);
        }
      }
    });
  }

  void _setInvalidPasswordState() {
    if (mounted) {
      setState(() {
        _error = LocaleKeys.incorrectPassword.tr();
        _inProgress = false;
      });
    }
  }
}
