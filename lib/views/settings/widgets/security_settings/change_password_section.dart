import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class ChangePasswordSection extends StatelessWidget {
  const ChangePasswordSection();

  @override
  Widget build(BuildContext context) {
    return isMobile ? const _MobileBody() : const _DesktopBody();
  }
}

class _DesktopBody extends StatelessWidget {
  const _DesktopBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(child: _TitleChangePasswordSection()),
          SizedBox(width: 8),
          _PasswordButton(),
        ],
      ),
    );
  }
}

class _MobileBody extends StatelessWidget {
  const _MobileBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TitleChangePasswordSection(),
          SizedBox(height: 21),
          _PasswordButton(),
        ],
      ),
    );
  }
}

class _TitleChangePasswordSection extends StatelessWidget {
  const _TitleChangePasswordSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          LocaleKeys.passwordTitle.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: isMobile ? 5 : 15),
        Text(
          LocaleKeys.changePasswordSpan1.tr(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        )
      ],
    );
  }
}

class _PasswordButton extends StatelessWidget {
  const _PasswordButton();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SecuritySettingsBloc>();

    return UiBorderButton(
      width: isMobile ? double.infinity : 191,
      height: isMobile ? 52 : 40,
      text: LocaleKeys.changeThePassword.tr(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      onPressed: () async => bloc.add(const PasswordUpdateEvent()),
    );
  }
}
