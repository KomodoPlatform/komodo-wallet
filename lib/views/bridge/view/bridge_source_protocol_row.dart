import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/bridge_form/bridge_bloc.dart';
import 'package:komodo_wallet/bloc/bridge_form/bridge_event.dart';
import 'package:komodo_wallet/bloc/bridge_form/bridge_state.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/dex_form_error.dart';
import 'package:komodo_wallet/views/bridge/bridge_source_protocol_selector_tile.dart';

class BridgeSourceProtocolRow extends StatelessWidget {
  const BridgeSourceProtocolRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BridgeBloc, BridgeState>(
      buildWhen: (prev, cur) {
        return prev.sellCoin != cur.sellCoin ||
            prev.selectedTicker != cur.selectedTicker;
      },
      builder: (context, state) {
        return BridgeSourceProtocolSelectorTile(
          coin: state.sellCoin,
          title: LocaleKeys.selectProtocol.tr(),
          onTap: () {
            if (state.selectedTicker == null) {
              context.read<BridgeBloc>().add(BridgeSetError(DexFormError(
                    error: LocaleKeys.bridgeSelectTokenFirstError.tr(),
                  )));
              return;
            }

            context
                .read<BridgeBloc>()
                .add(BridgeShowSourceDropdown(!state.showSourceDropdown));
          },
        );
      },
    );
  }
}
