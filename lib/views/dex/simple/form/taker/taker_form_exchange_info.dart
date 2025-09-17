import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_state.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_info_container.dart';
import 'package:web_dex/views/dex/simple/form/exchange_info/dex_compared_to_cex.dart';
import 'package:web_dex/views/dex/simple/form/taker/taker_form_exchange_rate.dart';
import 'package:web_dex/views/dex/simple/form/taker/taker_form_total_fees.dart';

class TakerFormExchangeInfo extends StatelessWidget {
  const TakerFormExchangeInfo();

  @override
  Widget build(BuildContext context) {
    return const DexInfoContainer(
      children: [
        TakerFormExchangeRate(),
        SizedBox(height: 8),
        _TakerComparedToCex(),
        SizedBox(height: 8),
        TakerFormTotalFees(),
      ],
    );
  }
}

class _TakerComparedToCex extends StatelessWidget {
  const _TakerComparedToCex({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TakerBloc, TakerState>(
      buildWhen: (prev, curr) {
        if (prev.selectedOrder != curr.selectedOrder) return true;
        if (prev.sellCoin != curr.sellCoin) return true;

        return false;
      },
      builder: (context, state) {
        final BestOrder? bestOrder = state.selectedOrder;
        final Coin? sellCoin = state.sellCoin;
        final coinsBloc = RepositoryProvider.of<CoinsRepo>(context);
        final Coin? buyCoin = bestOrder == null
            ? null
            : coinsBloc.getCoin(bestOrder.coin);

        return DexComparedToCex(
          base: sellCoin,
          rel: buyCoin,
          rate: bestOrder?.price,
        );
      },
    );
  }
}
