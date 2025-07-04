import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/settings/settings_bloc.dart';
import 'package:komodo_wallet/bloc/settings/settings_event.dart';
import 'package:komodo_wallet/bloc/settings/settings_state.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/views/settings/widgets/common/settings_section.dart';

class SettingsManageTestCoins extends StatelessWidget {
  const SettingsManageTestCoins({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: LocaleKeys.testCoins.tr(),
      child: const EnableTestCoinsSwitcher(),
    );
  }
}

class EnableTestCoinsSwitcher extends StatelessWidget {
  const EnableTestCoinsSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          UiSwitcher(
            key: const Key('enable-test-coins-switcher'),
            value: state.testCoinsEnabled,
            onChanged: (value) => _onSwitcherChanged(context, value),
          ),
          const SizedBox(width: 15),
          Text(LocaleKeys.enableTestCoins.tr()),
        ],
      ),
    );
  }

  void _onSwitcherChanged(BuildContext context, bool value) {
    context
        .read<SettingsBloc>()
        .add(TestCoinsEnabledChanged(testCoinsEnabled: value));
  }
}
