import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/views/dex/common/trading_amount_field.dart';
import 'package:web_dex/views/dex/simple/form/dex_fiat_amount.dart';

class BridgeTargetAmountRow extends StatelessWidget {
  const BridgeTargetAmountRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TargetAmount(),
        _FiatAmount(),
      ],
    );
  }
}

class _TargetAmount extends StatefulWidget {
  const _TargetAmount({Key? key}) : super(key: key);

  @override
  State<_TargetAmount> createState() => _TargetAmountState();
}

class _TargetAmountState extends State<_TargetAmount> {
  final _controller = TextEditingController();

  @override
  void initState() {
    final Rational? buyAmount = context.read<BridgeBloc>().state.buyAmount;
    formatAmountInput(_controller, buyAmount);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BridgeBloc, BridgeState>(
      listenWhen: (prev, cur) => prev.buyAmount != cur.buyAmount,
      listener: (context, state) {
        formatAmountInput(_controller, state.buyAmount);
      },
      child: TradingAmountField(
        controller: _controller,
        enabled: false,
        height: 18,
        contentPadding: const EdgeInsets.only(right: 12),
      ),
    );
  }
}

class _FiatAmount extends StatelessWidget {
  const _FiatAmount({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    return BlocBuilder<BridgeBloc, BridgeState>(
      buildWhen: (prev, cur) {
        return prev.bestOrder != cur.bestOrder ||
            prev.buyAmount != cur.buyAmount;
      },
      builder: (context, state) {
        final String? abbr = state.bestOrder?.coin;
        final Coin? coin = abbr == null ? null : coinsRepository.getCoin(abbr);

        return DexFiatAmount(
          coin: coin,
          amount: state.buyAmount,
          padding: const EdgeInsets.fromLTRB(0, 0, 14, 0),
        );
      },
    );
  }
}
