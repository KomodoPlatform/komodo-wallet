import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/validators.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';

class PasswordUpdatePage extends StatefulWidget {
  const PasswordUpdatePage({Key? key}) : super(key: key);

  @override
  State<PasswordUpdatePage> createState() => _PasswordUpdatePageState();
}

class _PasswordUpdatePageState extends State<PasswordUpdatePage> {
  bool _passwordUpdated = false;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SecuritySettingsBloc>();
    const event = ResetEvent();
    gotoSecurityMain() => bloc.add(event);

    late Widget pageContent;
    if (_passwordUpdated) {
      pageContent = _SuccessView(back: gotoSecurityMain);
    } else {
      pageContent = _FormView(
        onSuccess: () {
          setState(() => _passwordUpdated = true);
        },
      );
    }
    final scrollController = ScrollController();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .3),
          borderRadius: BorderRadius.circular(18.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isNotMobile)
            PageHeader(
              onBackButtonPressed: gotoSecurityMain,
              backText: LocaleKeys.back.tr(),
              title: LocaleKeys.changingWalletPassword.tr(),
            ),
          const SizedBox(height: 28),
          Flexible(
            child: DexScrollbar(
              isMobile: isMobile,
              scrollController: scrollController,
              child: SingleChildScrollView(
                controller: ScrollController(),
                child: SizedBox(
                  width: 270,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isMobile) ...{
                        Text(
                          '${LocaleKeys.changingWalletPassword.tr()} ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                      },
                      Text(
                        LocaleKeys.changingWalletPasswordDescription.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 21),
                      pageContent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatefulWidget {
  const _FormView({Key? key, required this.onSuccess}) : super(key: key);

  final VoidCallback onSuccess;

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  bool _isObscured = true;
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CurrentField(
            controller: _oldController,
            isObscured: _isObscured,
            onVisibilityChange: _onVisibilityChange,
            formKey: _formKey,
          ),
          const SizedBox(height: 30),
          _NewField(
            controller: _newController,
            isObscured: _isObscured,
            onVisibilityChange: _onVisibilityChange,
          ),
          const SizedBox(height: 20),
          _ConfirmField(
            confirmController: _confirmController,
            newController: _newController,
            isObscured: _isObscured,
            onVisibilityChange: _onVisibilityChange,
          ),
          const SizedBox(height: 30),
          if (_error != null) ...{
            Text(
              _error!,
              style: TextStyle(color: theme.currentGlobal.colorScheme.error),
            ),
            const SizedBox(height: 10),
          },
          UiPrimaryButton(
            onPressed: _onUpdate,
            text: LocaleKeys.updatePassword.tr(),
          ),
        ],
      ),
    );
  }

  Future<void> _onUpdate() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final currentWalletBloc = RepositoryProvider.of<CurrentWalletBloc>(context);
    final Wallet? wallet = currentWalletBloc.wallet;
    if (wallet == null) return;
    final String password = _newController.text;

    if (_oldController.text == password) {
      setState(() {
        _error = LocaleKeys.usedSamePassword.tr();
      });
      return;
    }

    final bool isPasswordUpdated = await currentWalletBloc.updatePassword(
      _oldController.text,
      password,
      wallet,
    );

    if (!isPasswordUpdated) {
      setState(() {
        _error = LocaleKeys.passwordNotAccepted.tr();
      });
      return;
    } else {
      setState(() => _error = null);
    }

    _newController.text = '';
    _confirmController.text = '';
    widget.onSuccess();
  }

  void _onVisibilityChange(bool isPasswordObscured) {
    setState(() {
      _isObscured = isPasswordObscured;
    });
  }
}

class _CurrentField extends StatefulWidget {
  const _CurrentField({
    required this.controller,
    required this.isObscured,
    required this.onVisibilityChange,
    required this.formKey,
  });

  final TextEditingController controller;
  final bool isObscured;
  final Function(bool) onVisibilityChange;
  final GlobalKey<FormState> formKey;

  @override
  State<_CurrentField> createState() => _CurrentFieldState();
}

class _CurrentFieldState extends State<_CurrentField> {
  String _seedError = '';

  @override
  Widget build(BuildContext context) {
    final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
    return _PasswordField(
      hintText: LocaleKeys.currentPassword.tr(),
      controller: widget.controller,
      isObscured: widget.isObscured,
      validator: (String? password) {
        if (password == null || password.isEmpty) {
          return LocaleKeys.passwordIsEmpty.tr();
        }

        if (_seedError.isNotEmpty) {
          final result = _seedError;
          _seedError = '';
          return result;
        }

        if (currentWallet == null) return LocaleKeys.walletNotFound.tr();

        _validateSeed(currentWallet, password);
        return null;
      },
      suffixIcon: PasswordVisibilityControl(
        onVisibilityChange: widget.onVisibilityChange,
      ),
    );
  }

  Future<void> _validateSeed(Wallet currentWallet, String password) async {
    // TODO!: determine if this needs to be reimplemented in the sdk or if it
    // can be removed entirely.
    // _seedError = '';
    // final seed = await currentWallet.getSeed(password);
    // if (seed.isNotEmpty) return;
    // _seedError = LocaleKeys.invalidPasswordError.tr();
    // widget.formKey.currentState?.validate();
  }
}

class _NewField extends StatelessWidget {
  const _NewField({
    required this.controller,
    required this.isObscured,
    required this.onVisibilityChange,
  });

  final TextEditingController controller;
  final bool isObscured;
  final Function(bool) onVisibilityChange;

  @override
  Widget build(BuildContext context) {
    return _PasswordField(
      hintText: LocaleKeys.enterNewPassword.tr(),
      controller: controller,
      isObscured: isObscured,
      validator: (String? password) => validatePassword(
        password ?? '',
        LocaleKeys.walletCreationFormatPasswordError.tr(),
      ),
      suffixIcon: PasswordVisibilityControl(
        onVisibilityChange: onVisibilityChange,
      ),
    );
  }
}

class _ConfirmField extends StatelessWidget {
  const _ConfirmField({
    required this.confirmController,
    required this.newController,
    required this.isObscured,
    required this.onVisibilityChange,
  });

  final TextEditingController confirmController;
  final TextEditingController newController;
  final bool isObscured;
  final Function(bool) onVisibilityChange;

  @override
  Widget build(BuildContext context) {
    return _PasswordField(
      hintText: LocaleKeys.confirmNewPassword.tr(),
      controller: confirmController,
      isObscured: isObscured,
      validator: (String? confirmPassword) => validateConfirmPassword(
        newController.text,
        confirmPassword ?? '',
      ),
      suffixIcon: PasswordVisibilityControl(
        onVisibilityChange: onVisibilityChange,
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.isObscured,
    required this.suffixIcon,
    required this.validator,
    required this.hintText,
  });

  final TextEditingController controller;
  final bool isObscured;
  final PasswordVisibilityControl suffixIcon;
  final String? Function(String?)? validator;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return UiTextFormField(
      autofocus: true,
      controller: controller,
      textInputAction: TextInputAction.none,
      autocorrect: false,
      enableInteractiveSelection: true,
      obscureText: isObscured,
      inputFormatters: [LengthLimitingTextInputFormatter(40)],
      validator: validator,
      errorMaxLines: 6,
      hintText: hintText,
      suffixIcon: suffixIcon,
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({Key? key, required this.back}) : super(key: key);

  final VoidCallback back;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: UiPrimaryButton(
            prefix: const Icon(Icons.check, color: Colors.white),
            backgroundColor: theme.custom.passwordButtonSuccessColor,
            onPressed: back,
            text: LocaleKeys.passwordHasChanged.tr(),
          ),
        ),
      ],
    );
  }
}
