import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/hidden_without_wallet.dart';
import 'package:web_dex/views/bridge/bridge_confirmation.dart';
import 'package:web_dex/views/bridge/bridge_exchange_form.dart';
import 'package:web_dex/views/bridge/view/bridge_header.dart';
import 'package:web_dex/views/bridge/view/table/bridge_source_protocols_table.dart';
import 'package:web_dex/views/bridge/view/table/bridge_target_protocols_table.dart';
import 'package:web_dex/views/bridge/view/table/bridge_tickers_list.dart';

class BridgeForm extends StatelessWidget {
  const BridgeForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return DexScrollbar(
      isMobile: isMobile,
      scrollController: scrollController,
      child: SingleChildScrollView(
        key: const Key('bridge-form-scroll'),
        controller: scrollController,
        child: BlocSelector<BridgeBloc, BridgeState, BridgeStep>(
          selector: (state) => state.step,
          builder: (context, step) {
            switch (step) {
              case BridgeStep.confirm:
                return const BridgeConfirmation();
              case BridgeStep.form:
                return ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: theme.custom.dexFormWidth),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HiddenWithoutWallet(child: SizedBox(height: 20)),
                      SizedBox(height: 25),
                      BridgeHeader(),
                      SizedBox(height: 20),
                      Flexible(child: _BridgeFormContent()),
                    ],
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _BridgeFormContent extends StatelessWidget {
  const _BridgeFormContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        BridgeExchangeForm(),
        _TickerDropdown(),
        _SourceDropdown(),
        _TargetDropdown(),
      ],
    );
  }
}

class _TickerDropdown extends StatelessWidget {
  const _TickerDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BridgeBloc, BridgeState, bool>(
      selector: (state) => state.showTickerDropdown,
      builder: (context, showTickerDropdown) {
        if (!showTickerDropdown) return const SizedBox.shrink();

        return BridgeTickersList(
          onSelect: (Coin coin) {
            context
                .read<BridgeBloc>()
                .add(BridgeTickerChanged(abbr2Ticker(coin.abbr)));
          },
        );
      },
    );
  }
}

class _SourceDropdown extends StatelessWidget {
  const _SourceDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BridgeBloc, BridgeState, bool>(
      selector: (state) => state.showSourceDropdown,
      builder: (context, showSourceDropdown) {
        if (!showSourceDropdown) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 98),
          child: BridgeSourceProtocolsTable(
            onSelect: (Coin coin) =>
                context.read<BridgeBloc>().add(BridgeSetSellCoin(coin)),
            onClose: () {
              context
                  .read<BridgeBloc>()
                  .add(const BridgeShowSourceDropdown(false));
            },
          ),
        );
      },
    );
  }
}

class _TargetDropdown extends StatelessWidget {
  const _TargetDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BridgeBloc, BridgeState, bool>(
      selector: (state) => state.showTargetDropdown,
      builder: (context, showTargetDropdown) {
        if (!showTargetDropdown) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 196),
          child: BridgeTargetProtocolsTable(
            onSelect: (BestOrder order) {
              context.read<BridgeBloc>().add(BridgeSelectBestOrder(order));
            },
            onClose: () => context
                .read<BridgeBloc>()
                .add(const BridgeShowTargetDropdown(false)),
          ),
        );
      },
    );
  }
}
