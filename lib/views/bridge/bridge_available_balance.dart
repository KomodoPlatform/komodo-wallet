import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/bridge_form/bridge_bloc.dart';
import 'package:komodo_wallet/bloc/bridge_form/bridge_state.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/available_balance.dart';

class BridgeAvailableBalance extends StatelessWidget {
  const BridgeAvailableBalance({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BridgeBloc, BridgeState>(
      buildWhen: (prev, cur) {
        return prev.maxSellAmount != cur.maxSellAmount ||
            prev.availableBalanceState != cur.availableBalanceState;
      },
      builder: (context, state) {
        return AvailableBalance(
          state.maxSellAmount,
          state.availableBalanceState,
        );
      },
    );
  }
}
