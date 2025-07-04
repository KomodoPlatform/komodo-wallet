import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_state.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';
import 'package:komodo_wallet/views/dex/common/trading_amount_field.dart';
import 'package:komodo_wallet/views/dex/dex_helpers.dart';

class TakerFormBuyAmount extends StatelessWidget {
  const TakerFormBuyAmount(this.isEnabled);

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 18, top: 1),
          child: _BuyAmountInput(
            key: const Key('taker-buy-amount'),
            isEnabled: isEnabled,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 18),
          child: _BuyPriceField(),
        ),
      ],
    );
  }
}

class _BuyPriceField extends StatelessWidget {
  const _BuyPriceField();

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle = Theme.of(context).textTheme.bodySmall;

    return BlocBuilder<TakerBloc, TakerState>(
      buildWhen: (prev, curr) {
        if (prev.selectedOrder != curr.selectedOrder) return true;
        if (prev.buyAmount != curr.buyAmount) return true;

        return false;
      },
      builder: (context, state) {
        final BestOrder? order = state.selectedOrder;
        if (order == null) return const SizedBox();

        final amount = state.buyAmount ?? Rational.zero;
        return Text(
          getFormattedFiatAmount(context, order.coin, amount),
          style: textStyle,
        );
      },
    );
  }
}

class _BuyAmountInput extends StatelessWidget {
  _BuyAmountInput({
    Key? key,
    required this.isEnabled,
  }) : super(key: key);

  final bool isEnabled;

  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TakerBloc, TakerState, Rational?>(
      selector: (state) => state.buyAmount,
      builder: (context, buyAmount) {
        formatAmountInput(_textController, buyAmount);

        return TradingAmountField(
          controller: _textController,
          enabled: isEnabled,
        );
      },
    );
  }
}
