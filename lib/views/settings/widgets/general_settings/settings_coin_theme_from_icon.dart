import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_event.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/settings/widgets/common/settings_section.dart';

class SettingsCoinThemeFromIcon extends StatelessWidget {
  const SettingsCoinThemeFromIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: LocaleKeys.coinThemeFromIcon.tr(),
      child: const _CoinThemeSwitcher(),
    );
  }
}

class _CoinThemeSwitcher extends StatelessWidget {
  const _CoinThemeSwitcher();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) => Row(
        children: [
          UiSwitcher(
            key: const Key('coin-theme-from-icon-switcher'),
            value: state.coinThemeFromIcon,
            onChanged: (value) => _onChanged(context, value),
          ),
          const SizedBox(width: 15),
          Text(LocaleKeys.coinThemeFromIcon.tr()),
        ],
      ),
    );
  }

  void _onChanged(BuildContext context, bool value) {
    context.read<SettingsBloc>().add(CoinThemeFromIconChanged(enabled: value));
  }
}
