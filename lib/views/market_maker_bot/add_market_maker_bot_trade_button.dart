import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/system_health/system_health_bloc.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class AddMarketMakerBotTradeButton extends StatelessWidget {
  const AddMarketMakerBotTradeButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemHealthBloc, SystemHealthState>(
      builder: (context, systemHealthState) {
        final tradingStatusBloc = context.watch<TradingStatusBloc>();

        final bool tradingEnabled = tradingStatusBloc.state.isEnabled;

        return Opacity(
          opacity: !enabled ? 0.8 : 1,
          child: UiPrimaryButton(
            key: const Key('make-order-button'),
            text: tradingEnabled
                ? LocaleKeys.makeOrder.tr()
                : LocaleKeys.tradingDisabled.tr(),
            onPressed: !enabled || !tradingEnabled ? null : () => onPressed(),
            height: 40,
          ),
        );
      },
    );
  }
}
