import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:komodo_wallet/bloc/bridge_form/bridge_bloc.dart';
import 'package:komodo_wallet/bloc/bridge_form/bridge_event.dart';
import 'package:komodo_wallet/bloc/bridge_form/bridge_state.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';
import 'package:komodo_wallet/views/dex/common/trading_amount_field.dart';
import 'package:komodo_wallet/views/dex/simple/form/dex_fiat_amount.dart';

class BridgeSourceAmountGroup extends StatelessWidget {
  const BridgeSourceAmountGroup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BridgeBloc, BridgeState, Coin?>(
      selector: (state) => state.sellCoin,
      builder: (context, sellCoin) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AmountField(sellCoin),
            _FiatAmount(sellCoin),
          ],
        );
      },
    );
  }
}

class _FiatAmount extends StatelessWidget {
  const _FiatAmount(this.coin, {Key? key}) : super(key: key);

  final Coin? coin;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BridgeBloc, BridgeState, Rational?>(
      selector: (state) => state.sellAmount,
      builder: (context, sellAmount) {
        return DexFiatAmount(
          coin: coin,
          amount: sellAmount,
          padding: const EdgeInsets.fromLTRB(0, 0, 14, 0),
        );
      },
    );
  }
}

class _AmountField extends StatefulWidget {
  const _AmountField(this.coin);

  final Coin? coin;

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    final Rational? sellAmount = context.read<BridgeBloc>().state.sellAmount;
    formatAmountInput(_controller, sellAmount);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BridgeBloc, BridgeState>(
      listenWhen: (prev, cur) => prev.sellAmount != cur.sellAmount,
      listener: (context, state) =>
          formatAmountInput(_controller, state.sellAmount),
      buildWhen: (prev, cur) => prev.sellCoin != cur.sellCoin,
      builder: (context, state) {
        final bool isEnabled = state.sellCoin != null;

        return GestureDetector(
          onTap: !isEnabled
              ? () => context
                  .read<BridgeBloc>()
                  .add(const BridgeShowSourceDropdown(true))
              : null,
          child: TradingAmountField(
            controller: _controller,
            enabled: isEnabled,
            height: 18,
            contentPadding: const EdgeInsets.only(right: 12),
            onChanged: (String value) {
              final bloc = context.read<BridgeBloc>();

              bloc.add(BridgeSellAmountChange(value));
              if (value.isEmpty) {
                bloc.add(const BridgeShowTargetDropdown(false));
              }
            },
          ),
        );
      },
    );
  }
}
