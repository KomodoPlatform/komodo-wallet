import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_event.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_state.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';
import 'package:komodo_wallet/views/dex/common/trading_amount_field.dart';
import 'package:komodo_wallet/views/dex/dex_helpers.dart';

class TakerFormSellAmount extends StatelessWidget {
  const TakerFormSellAmount(this.isEnabled);

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 18, top: 1),
          child: _SellAmountInput(
            key: const Key('taker-sell-amount'),
            isEnabled: isEnabled,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 18),
          child: _SellPriceField(),
        ),
      ],
    );
  }
}

class _SellPriceField extends StatelessWidget {
  const _SellPriceField();

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle = Theme.of(context).textTheme.bodySmall;

    return BlocBuilder<TakerBloc, TakerState>(buildWhen: (prev, curr) {
      if (prev.sellCoin != curr.sellCoin) return true;
      if (prev.sellAmount != curr.sellAmount) return true;

      return false;
    }, builder: (context, state) {
      final coin = state.sellCoin;
      if (coin == null) return const SizedBox();

      final amount = state.sellAmount ?? Rational.zero;
      return Text(
        getFormattedFiatAmount(context, coin.abbr, amount),
        style: textStyle,
      );
    });
  }
}

class _SellAmountInput extends StatelessWidget {
  _SellAmountInput({
    Key? key,
    required this.isEnabled,
  }) : super(key: key);

  final bool isEnabled;

  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TakerBloc, TakerState, Rational?>(
      selector: (state) => state.sellAmount,
      builder: (context, sellAmount) {
        formatAmountInput(_textController, sellAmount);

        return TradingAmountField(
          controller: _textController,
          enabled: isEnabled,
          onChanged: (String value) {
            context.read<TakerBloc>().add(TakerSellAmountChange(value));

            if (value.isEmpty) {
              context.read<TakerBloc>().add(TakerOrderSelectorOpen(false));
            }
          },
        );
      },
    );
  }
}
