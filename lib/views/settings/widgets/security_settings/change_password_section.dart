import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/settings/widgets/security_settings/security_action_plate.dart';

class ChangePasswordSection extends StatelessWidget {
  const ChangePasswordSection();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SecuritySettingsBloc>();

    return SecurityActionPlate(
      icon: const Icon(Icons.lock),
      title: LocaleKeys.passwordTitle.tr(),
      description: LocaleKeys.changePasswordSpan1.tr(),
      actionText: LocaleKeys.changeThePassword.tr(),
      onActionPressed: () async => bloc.add(const PasswordUpdateEvent()),
    );
  }
}
