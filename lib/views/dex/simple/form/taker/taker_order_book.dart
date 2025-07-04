import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_repo.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_event.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_state.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:komodo_wallet/model/orderbook/order.dart';
import 'package:komodo_wallet/views/dex/orderbook/orderbook_view.dart';

class TakerOrderbook extends StatelessWidget {
  const TakerOrderbook();

  @override
  Widget build(BuildContext context) {
    final coinsBloc = RepositoryProvider.of<CoinsRepo>(context);
    return BlocBuilder<TakerBloc, TakerState>(
      buildWhen: (prev, cur) {
        if (prev.sellCoin?.abbr != cur.sellCoin?.abbr) return true;
        if (prev.selectedOrder?.uuid != cur.selectedOrder?.uuid) return true;

        return false;
      },
      builder: (context, state) {
        final selectedOrder = state.selectedOrder;

        return OrderbookView(
          base: state.sellCoin,
          rel: selectedOrder == null
              ? null
              : coinsBloc.getCoin(selectedOrder.coin),
          selectedOrderUuid: state.selectedOrder?.uuid,
          onBidClick: (Order order) {
            if (state.selectedOrder?.uuid == order.uuid) return;
            context.read<TakerBloc>().add(TakerSelectOrder(
                BestOrder.fromOrder(order, state.selectedOrder?.coin)));
          },
        );
      },
    );
  }
}
