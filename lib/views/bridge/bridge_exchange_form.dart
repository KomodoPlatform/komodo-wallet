import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/bloc/system_health/system_health_bloc.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/widgets/connect_wallet/connect_wallet_wrapper.dart';
import 'package:web_dex/views/bridge/bridge_group.dart';
import 'package:web_dex/views/bridge/bridge_source_protocol_header.dart';
import 'package:web_dex/views/bridge/bridge_target_protocol_header.dart';
import 'package:web_dex/views/bridge/bridge_ticker_selector.dart';
import 'package:web_dex/views/bridge/bridge_total_fees.dart';
import 'package:web_dex/views/bridge/view/bridge_exchange_rate.dart';
import 'package:web_dex/views/bridge/view/bridge_source_amount_group.dart';
import 'package:web_dex/views/bridge/view/bridge_source_protocol_row.dart';
import 'package:web_dex/views/bridge/view/bridge_target_amount_row.dart';
import 'package:web_dex/views/bridge/view/bridge_target_protocol_row.dart';
import 'package:web_dex/views/bridge/view/error_list/bridge_form_error_list.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';

class BridgeExchangeForm extends StatefulWidget {
  const BridgeExchangeForm({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BridgeExchangeFormState();
}

class _BridgeExchangeFormState extends State<BridgeExchangeForm> {
  @override
  void initState() {
    final bridgeBloc = context.read<BridgeBloc>();
    final authBlocState = context.read<AuthBloc>().state;
    bridgeBloc.add(const BridgeInit(ticker: defaultDexCoin));
    bridgeBloc.add(BridgeSetWalletIsReady(authBlocState.isSignedIn));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bridgeBloc = context.read<BridgeBloc>();
    return BlocListener<AuthBloc, AuthBlocState>(
      listenWhen: (previous, current) =>
          previous.isSignedIn != current.isSignedIn,
      listener: (context, state) =>
          bridgeBloc.add(BridgeSetWalletIsReady(state.isSignedIn)),
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          BridgeTickerSelector(),
          SizedBox(height: 30),
          BridgeGroup(
            header: SourceProtocolHeader(),
            child: SourceProtocol(),
          ),
          SizedBox(height: 19),
          BridgeGroup(
            header: TargetProtocolHeader(),
            child: TargetProtocol(),
          ),
          SizedBox(height: 12),
          BridgeFormErrorList(),
          SizedBox(height: 12),
          BridgeExchangeRate(),
          SizedBox(height: 12),
          BridgeTotalFees(),
          SizedBox(height: 24),
          _ExchangeButton(),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}

class SourceProtocol extends StatelessWidget {
  const SourceProtocol({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: BridgeSourceProtocolRow()),
        Flexible(child: BridgeSourceAmountGroup()),
      ],
    );
  }
}

class TargetProtocol extends StatelessWidget {
  const TargetProtocol({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: BridgeTargetProtocolRow()),
        Flexible(child: BridgeTargetAmountRow()),
      ],
    );
  }
}

class _ExchangeButton extends StatelessWidget {
  const _ExchangeButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemHealthBloc, SystemHealthState>(
        builder: (context, systemHealthState) {
      // Determine if system clock is valid
      final isSystemClockValid = systemHealthState is SystemHealthLoadSuccess &&
          systemHealthState.isValid;

      final tradingStatusState = context.watch<TradingStatusBloc>().state;
      final tradingEnabled = tradingStatusState.isEnabled;

      return BlocSelector<BridgeBloc, BridgeState, bool>(
          selector: (state) => state.inProgress,
          builder: (context, inProgress) {
            final isDisabled = inProgress || !isSystemClockValid;
            return SizedBox(
              width: theme.custom.dexFormWidth,
              child: ConnectWalletWrapper(
                eventType: WalletsManagerEventType.bridge,
                child: Opacity(
                  opacity: isDisabled ? 0.8 : 1,
                  child: SizedBox(
                    width: theme.custom.dexFormWidth,
                    child: UiPrimaryButton(
                      height: 40,
                      prefix: inProgress ? const _Spinner() : null,
                      text: tradingEnabled
                          ? LocaleKeys.exchange.tr()
                          : LocaleKeys.tradingDisabled.tr(),
                      onPressed: isDisabled || !tradingEnabled
                          ? null
                          : () => _onPressed(context),
                    ),
                  ),
                ),
              ),
            );
          });
    });
  }

  void _onPressed(BuildContext context) {
    context.read<BridgeBloc>().add(const BridgeSubmitClick());
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: UiSpinner(
        width: 10,
        height: 10,
        strokeWidth: 1,
        color: theme.custom.defaultGradientButtonTextColor,
      ),
    );
  }
}
