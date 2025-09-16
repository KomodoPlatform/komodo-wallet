import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/dex_form_error.dart';
import 'package:web_dex/views/bridge/bridge_target_protocol_selector_tile.dart';

class BridgeTargetProtocolRow extends StatelessWidget {
  const BridgeTargetProtocolRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BridgeBloc, BridgeState>(
      buildWhen: (prev, cur) {
        return prev.bestOrder != cur.bestOrder || prev.sellCoin != cur.sellCoin;
      },
      builder: (context, state) {
        return BridgeTargetProtocolSelectorTile(
          bestOrder: state.bestOrder,
          title: LocaleKeys.selectProtocol.tr(),
          onTap: () {
            if (state.sellCoin == null) {
              context.read<BridgeBloc>().add(BridgeSetError(DexFormError(
                    error: LocaleKeys.bridgeSelectFromProtocolError.tr(),
                  )));
              return;
            }

            final bridgeBloc = context.read<BridgeBloc>();
            bridgeBloc.add(
                BridgeShowTargetDropdown(!bridgeBloc.state.showTargetDropdown));
          },
        );
      },
    );
  }
}
