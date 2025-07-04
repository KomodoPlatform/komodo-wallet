import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_state.dart';
import 'package:komodo_wallet/model/trade_preimage.dart';
import 'package:komodo_wallet/views/dex/simple/form/exchange_info/total_fees.dart';

class TakerFormTotalFees extends StatelessWidget {
  const TakerFormTotalFees();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TakerBloc, TakerState, TradePreimage?>(
      selector: (state) => state.tradePreimage,
      builder: (context, tradePreimage) {
        return TotalFees(preimage: tradePreimage);
      },
    );
  }
}
