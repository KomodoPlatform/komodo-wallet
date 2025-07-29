import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_event.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/settings/widgets/common/settings_section.dart';

class SettingsManageTradingBot extends StatelessWidget {
  const SettingsManageTradingBot({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSection(
          title: LocaleKeys.expertMode.tr(),
          child: const EnableTradingBotSwitcher(),
        ),
      ],
    );
  }
}

class EnableTradingBotSwitcher extends StatelessWidget {
  const EnableTradingBotSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          UiSwitcher(
            key: const Key('enable-trading-bot-switcher'),
            value: state.mmBotSettings.isMMBotEnabled,
            onChanged: (value) => _onSwitcherChanged(context, value),
          ),
          const SizedBox(width: 15),
          Text(LocaleKeys.enableTradingBot.tr()),
        ],
      ),
    );
  }

  void _onSwitcherChanged(BuildContext context, bool value) {
    final settings = context.read<SettingsBloc>().state.mmBotSettings.copyWith(
      isMMBotEnabled: value,
    );
    context.read<SettingsBloc>().add(MarketMakerBotSettingsChanged(settings));

    if (!value) {
      context.read<MarketMakerBotBloc>().add(
        const MarketMakerBotStopRequested(),
      );
    }
  }
}
