import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';
import 'package:web_dex/views/wallets_manager/widgets/hdwallet_mode_switch.dart';

class WalletLogIn extends StatefulWidget {
  const WalletLogIn({
    Key? key,
    required this.wallet,
    required this.onLogin,
    required this.onCancel,
    this.errorText,
  }) : super(key: key);

  final Wallet wallet;
  final void Function(String, Wallet) onLogin;
  final void Function() onCancel;
  final String? errorText;

  @override
  State<WalletLogIn> createState() => _WalletLogInState();
}

class _WalletLogInState extends State<WalletLogIn> {
  bool _isPasswordObscured = true;
  bool _errorDisplay = false;
  final _backKeyButton = GlobalKey();
  final TextEditingController _passwordController = TextEditingController();
  bool _inProgress = false;
  bool _isHdMode = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    setState(() {
      _errorDisplay = true;
      _inProgress = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.wallet.config.type =
          _isHdMode ? WalletType.hdwallet : WalletType.iguana;
      widget.onLogin(
        _passwordController.text,
        widget.wallet,
      );

      if (mounted) setState(() => _inProgress = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text(LocaleKeys.walletLogInTitle.tr(),
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
        const SizedBox(height: 40),
        _buildWalletField(),
        const SizedBox(
          height: 20,
        ),
        _buildPasswordField(),
        const SizedBox(height: 20),
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
            text: _inProgress
                ? '${LocaleKeys.pleaseWait.tr()}...'
                : LocaleKeys.logIn.tr(),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            onPressed: _inProgress ? null : _submitLogin,
          ),
        ),
        const SizedBox(height: 20),
        UiUnderlineTextButton(
          key: _backKeyButton,
          onPressed: () {
            widget.onCancel();
          },
          text: LocaleKeys.cancel.tr(),
        ),
      ],
    );
  }

  Widget _buildWalletField() {
    return UiTextFormField(
      key: const Key('wallet-field'),
      initialValue: widget.wallet.name,
      readOnly: true,
      autocorrect: false,
      enableInteractiveSelection: true,
    );
  }

  Widget _buildPasswordField() {
    return Stack(
      children: [
        UiTextFormField(
          key: const Key('create-password-field'),
          controller: _passwordController,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableInteractiveSelection: true,
          obscureText: _isPasswordObscured,
          errorText: !_inProgress && _errorDisplay ? widget.errorText : null,
          hintText: LocaleKeys.walletCreationPasswordHint.tr(),
          onChanged: (text) {
            if (text == '') {
              setState(() {
                _errorDisplay = false;
              });
            }
          },
          suffixIcon: PasswordVisibilityControl(
            onVisibilityChange: (bool isPasswordObscured) {
              setState(() {
                _isPasswordObscured = isPasswordObscured;
              });
            },
          ),
          onFieldSubmitted: (text) {
            if (!_inProgress) _submitLogin();
          },
        ),
      ],
    );
  }
}
