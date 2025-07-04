import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/blocs/maker_form_bloc.dart';
import 'package:komodo_wallet/model/trade_preimage.dart';
import 'package:komodo_wallet/views/dex/simple/form/exchange_info/total_fees.dart';

class MakerFormTotalFees extends StatelessWidget {
  const MakerFormTotalFees({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    return StreamBuilder<TradePreimage?>(
        initialData: makerFormBloc.preimage,
        stream: makerFormBloc.outPreimage,
        builder: (context, snapshot) {
          return TotalFees(preimage: snapshot.data);
        });
  }
}
