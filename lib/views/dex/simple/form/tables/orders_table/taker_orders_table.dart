import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_state.dart';
import 'package:komodo_wallet/views/dex/simple/form/tables/orders_table/orders_table.dart';

class TakerOrdersTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<TakerBloc, TakerState, bool>(
      selector: (state) => state.showOrderSelector,
      builder: (context, showOrdersSelector) {
        if (!showOrdersSelector) return const SizedBox();

        return const OrdersTable(key: Key('taker-orders-table'));
      },
    );
  }
}
