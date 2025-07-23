import 'dart:async';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';
import 'package:web_dex/views/wallets_manager/widgets/hdwallet_mode_switch.dart';

class WalletLogIn extends StatefulWidget {
  const WalletLogIn({
    required this.wallet,
    required this.onLogin,
    required this.onCancel,
    this.initialHdMode = false,
    super.key,
  });

  final Wallet wallet;
  final void Function(String, Wallet) onLogin;
  final void Function() onCancel;
  final bool initialHdMode;

  @override
  State<WalletLogIn> createState() => _WalletLogInState();
}

class _WalletLogInState extends State<WalletLogIn> {
  final _backKeyButton = GlobalKey();
  final TextEditingController _passwordController = TextEditingController();
  late bool _isHdMode;
  KdfUser? _user;

  @override
  void initState() {
    super.initState();
    _isHdMode = widget.initialHdMode;
    unawaited(_fetchKdfUser());
  }

  Future<void> _fetchKdfUser() async {
    final kdfSdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    final users = await kdfSdk.auth.getUsers();
    final user = users
        .firstWhereOrNull((user) => user.walletId.name == widget.wallet.name);

    if (user != null) {
      setState(() {
        _user = user;
        _isHdMode = user.wallet.config.type == WalletType.hdwallet;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    final authState = context.read<AuthBloc>().state;
    if (authState.isLoading) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.wallet.config.type =
          _isHdMode && _user != null && _user!.isBip39Seed == true
              ? WalletType.hdwallet
              : WalletType.iguana;

      widget.onLogin(
        _passwordController.text,
        widget.wallet,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        final errorMessage =
            state.authError?.type == AuthExceptionType.incorrectPassword
                ? LocaleKeys.incorrectPassword.tr()
                : state.authError?.message;

        return Column(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              LocaleKeys.walletLogInTitle.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 40),
            UiTextFormField(
              key: const Key('wallet-field'),
              initialValue: widget.wallet.name,
              readOnly: true,
              autocorrect: false,
            ),
            const SizedBox(
              height: 20,
            ),
            PasswordTextField(
              onFieldSubmitted: state.isLoading ? null : _submitLogin,
              controller: _passwordController,
              errorText: errorMessage,
            ),
            const SizedBox(height: 20),
            if (_user != null && _user!.isBip39Seed == true)
              HDWalletModeSwitch(
                value: _isHdMode,
                onChanged: (value) {
                  setState(() => _isHdMode = value);
                },
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: UiPrimaryButton(
                height: 50,
                text: state.isLoading
                    ? '${LocaleKeys.pleaseWait.tr()}...'
                    : LocaleKeys.logIn.tr(),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                onPressed: state.isLoading ? null : _submitLogin,
              ),
            ),
            const SizedBox(height: 20),
            UiUnderlineTextButton(
              key: _backKeyButton,
              onPressed: widget.onCancel,
              text: LocaleKeys.cancel.tr(),
            ),
          ],
        );
      },
    );
  }
}

class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    required this.onFieldSubmitted,
    required this.controller,
    super.key,
    this.errorText,
  });

  final String? errorText;
  final TextEditingController controller;
  final void Function()? onFieldSubmitted;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isPasswordObscured = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        UiTextFormField(
          key: const Key('create-password-field'),
          autofocus: true,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          controller: widget.controller,
          obscureText: _isPasswordObscured,
          errorText: widget.errorText,
          hintText: LocaleKeys.walletCreationPasswordHint.tr(),
          suffixIcon: PasswordVisibilityControl(
            onVisibilityChange: onVisibilityChange,
          ),
          onFieldSubmitted: (_) => widget.onFieldSubmitted?.call(),
        ),
      ],
    );
  }

  // ignore: avoid_positional_boolean_parameters
  void onVisibilityChange(bool isPasswordObscured) {
    setState(() {
      _isPasswordObscured = isPasswordObscured;
    });
  }
}
