import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/router/state/wallet_state.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class CoinsManagerSwitchButton extends StatelessWidget {
  const CoinsManagerSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CoinsManagerBloc>().state;

    return UiPrimaryButton(
      buttonKey: const Key('coins-manager-switch-button'),
      prefix: state.isSwitching
          ? Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UiSpinner(
                color: theme.custom.defaultGradientButtonTextColor,
                width: 14,
                height: 14,
              ),
            )
          : null,
      text: state.action == CoinsManagerAction.add
          ? LocaleKeys.addAssets.tr()
          : LocaleKeys.removeAssets.tr(),
      width: 260,
      onPressed: state.selectedCoins.isNotEmpty
          ? () => context
              .read<CoinsManagerBloc>()
              .add(const CoinsManagerCoinsSwitch())
          : null,
    );
  }
}
