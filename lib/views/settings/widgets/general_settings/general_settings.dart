import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/trading_status/trading_status_bloc.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/shared/widgets/hidden_with_wallet.dart';
import 'package:komodo_wallet/shared/widgets/hidden_without_wallet.dart';
import 'package:komodo_wallet/views/settings/widgets/general_settings/import_swaps.dart';
import 'package:komodo_wallet/views/settings/widgets/general_settings/settings_download_logs.dart';
import 'package:komodo_wallet/views/settings/widgets/general_settings/settings_manage_analytics.dart';
import 'package:komodo_wallet/views/settings/widgets/general_settings/settings_manage_test_coins.dart';
import 'package:komodo_wallet/views/settings/widgets/general_settings/settings_manage_trading_bot.dart';
import 'package:komodo_wallet/views/settings/widgets/general_settings/settings_manage_weak_passwords.dart';
import 'package:komodo_wallet/views/settings/widgets/general_settings/settings_reset_activated_coins.dart';
import 'package:komodo_wallet/views/settings/widgets/general_settings/settings_theme_switcher.dart';
import 'package:komodo_wallet/views/settings/widgets/general_settings/show_swap_data.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) const SizedBox(height: 20),
        const SettingsThemeSwitcher(),
        const SizedBox(height: 25),
        const SettingsManageAnalytics(),
        const SizedBox(height: 25),
        const SettingsManageTestCoins(),
        const SizedBox(height: 25),
        const SettingsManageWeakPasswords(),
        const SizedBox(height: 25),
        if (context.watch<TradingStatusBloc>().state is TradingEnabled)
          const HiddenWithoutWallet(
            child: SettingsManageTradingBot(),
          ),
        const SizedBox(height: 25),
        const SettingsDownloadLogs(),
        const SizedBox(height: 25),
        const HiddenWithWallet(
          child: SettingsResetActivatedCoins(),
        ),
        const SizedBox(height: 25),
        const HiddenWithoutWallet(
          isHiddenForHw: true,
          child: ShowSwapData(),
        ),
        const HiddenWithoutWallet(
          isHiddenForHw: true,
          child: ImportSwaps(),
        ),
      ],
    );
  }
}
