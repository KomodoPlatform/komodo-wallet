import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_state.dart';
import 'package:komodo_wallet/views/dex/simple/form/exchange_info/exchange_rate.dart';

class TakerFormExchangeRate extends StatelessWidget {
  const TakerFormExchangeRate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TakerBloc, TakerState>(
      buildWhen: (prev, curr) {
        if (prev.selectedOrder != curr.selectedOrder) return true;
        if (prev.sellCoin != curr.sellCoin) return true;

        return false;
      },
      builder: (context, state) {
        final String? base = state.sellCoin?.abbr;
        final String? rel = state.selectedOrder?.coin;
        final Rational? rate = state.selectedOrder?.price;

        return ExchangeRate(rate: rate, base: base, rel: rel);
      },
    );
  }
}
