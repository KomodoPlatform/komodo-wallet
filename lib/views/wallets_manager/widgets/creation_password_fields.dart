import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/validators.dart';
import 'package:web_dex/shared/widgets/password_visibility_control.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class CreationPasswordFields extends StatefulWidget {
  const CreationPasswordFields({
    Key? key,
    required this.passwordController,
    this.onFieldSubmitted,
  }) : super(key: key);

  final TextEditingController passwordController;
  final void Function(String)? onFieldSubmitted;

  @override
  State<CreationPasswordFields> createState() => _CreationPasswordFieldsState();
}

class _CreationPasswordFieldsState extends State<CreationPasswordFields> {
  final TextEditingController _confirmPasswordController =
      TextEditingController(text: '');
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPasswordField(),
        const SizedBox(height: 20),
        _buildPasswordConfirmationField(),
      ],
    );
  }

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.passwordController.text.isNotEmpty) {
      widget.passwordController.text = '';
    }
    super.initState();
  }

  Widget _buildPasswordConfirmationField() {
    return UiTextFormField(
      key: const Key('create-password-field-confirm'),
      controller: _confirmPasswordController,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      obscureText: _isObscured,
      enableInteractiveSelection: true,
      validationMode: InputValidationMode.eager,
      inputFormatters: [LengthLimitingTextInputFormatter(40)],
      validator: _validateConfirmPasswordField,
      onFieldSubmitted: widget.onFieldSubmitted,
      errorMaxLines: 6,
      autofillHints: const [AutofillHints.newPassword],
      hintText: LocaleKeys.walletCreationConfirmPasswordHint.tr(),
    );
  }

  Widget _buildPasswordField() {
    return UiTextFormField(
      key: const Key('create-password-field'),
      controller: widget.passwordController,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableInteractiveSelection: true,
      obscureText: _isObscured,
      inputFormatters: [LengthLimitingTextInputFormatter(40)],
      validator: _validatePasswordField,
      errorMaxLines: 6,
      autofillHints: const [AutofillHints.newPassword],
      hintText: LocaleKeys.walletCreationPasswordHint.tr(),
      suffixIcon: PasswordVisibilityControl(
        onVisibilityChange: (bool isPasswordObscured) {
          setState(() {
            _isObscured = isPasswordObscured;
          });
        },
      ),
    );
  }

  String? _validatePasswordField(String? passwordFieldInput) {
    final settingsBlocState = context.read<SettingsBloc>().state;
    final allowWeakPassword = settingsBlocState.weakPasswordsAllowed;
    final password = passwordFieldInput ?? '';

    if (allowWeakPassword) {
      return null;
    }

    return validatePassword(password);
  }

  String? _validateConfirmPasswordField(String? confirmPasswordFieldInput) {
    final originalPassword = widget.passwordController.text;

    return validateConfirmPassword(
      originalPassword,
      confirmPasswordFieldInput ?? '',
    );
  }
}
