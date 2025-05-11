import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_event.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/settings/widgets/common/settings_section.dart';

class SettingsManageWeakPasswords extends StatelessWidget {
  const SettingsManageWeakPasswords({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: LocaleKeys.passwordSecurity.tr(),
      child: const AllowWeakPasswordsSwitcher(),
    );
  }
}

class AllowWeakPasswordsSwitcher extends StatelessWidget {
  const AllowWeakPasswordsSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) => Row(
        children: [
          UiSwitcher(
            key: const Key('allow-weak-passwords-switcher'),
            value: state.weakPasswordsAllowed,
            onChanged: (value) => _onSwitcherChanged(context, value),
          ),
          const SizedBox(width: 15),
          Text(LocaleKeys.allowWeakPassword.tr()),
        ],
      ),
    );
  }

  void _onSwitcherChanged(BuildContext context, bool value) {
    context
        .read<SettingsBloc>()
        .add(WeakPasswordsAllowedChanged(weakPasswordsAllowed: value));
  }
}
