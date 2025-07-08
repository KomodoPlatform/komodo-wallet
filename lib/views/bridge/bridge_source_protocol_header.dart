import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/bridge/bridge_available_balance.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_form_group_header.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_small_button.dart';

class SourceProtocolHeader extends StatelessWidget {
  const SourceProtocolHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DexFormGroupHeader(
      title: LocaleKeys.from.tr().toUpperCase(),
      actions: const [
        BridgeAvailableBalance(),
        SizedBox(width: 12),
        _HalfMaxButtons()
      ],
    );
  }
}

class _HalfMaxButtons extends StatelessWidget {
  const _HalfMaxButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BridgeBloc, BridgeState>(
      buildWhen: (prev, cur) {
        return prev.sellCoin != cur.sellCoin ||
            prev.maxSellAmount != cur.maxSellAmount;
      },
      builder: (context, state) {
        final bool showMaxButton =
            state.sellCoin != null && state.maxSellAmount != null;

        return !showMaxButton
            ? const SizedBox.shrink()
            : Row(
                children: [
                  _HalfButton(),
                  const SizedBox(width: 10),
                  _MaxButton(),
                ],
              );
      },
    );
  }
}

class _MaxButton extends DexSmallButton {
  _MaxButton()
      : super(LocaleKeys.max.tr().toLowerCase(), (context) {
          final BridgeBloc bridgeBloc = BlocProvider.of<BridgeBloc>(context);
          bridgeBloc.add(BridgeAmountButtonClick(1));
        });
}

class _HalfButton extends DexSmallButton {
  _HalfButton()
      : super(LocaleKeys.half.tr().toLowerCase(), (context) {
          final BridgeBloc bridgeBloc = BlocProvider.of<BridgeBloc>(context);
          bridgeBloc.add(BridgeAmountButtonClick(0.5));
        });
}
