import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/blocs/maker_form_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';

class MakerFormBuyAmount extends StatelessWidget {
  const MakerFormBuyAmount(this.isEnabled, {Key? key}) : super(key: key);

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 18, top: 1),
            child: _BuyAmountInput(
              key: const Key('maker-buy-amount'),
              isEnabled: isEnabled,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 18),
            child: _BuyAmountFiat(),
          ),
        ],
      ),
    );
  }
}

class _BuyAmountFiat extends StatelessWidget {
  const _BuyAmountFiat();

  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    final TextStyle? textStyle = Theme.of(context).textTheme.bodySmall;
    return StreamBuilder<Rational?>(
      initialData: makerFormBloc.buyAmount,
      stream: makerFormBloc.outBuyAmount,
      builder: (context, snapshot) {
        final Coin? coin = makerFormBloc.buyCoin;
        if (coin == null) return const SizedBox();
        final amount = snapshot.data ?? Rational.zero;

        return Text(
          getFormattedFiatAmount(context, coin.abbr, amount),
          style: textStyle,
        );
      },
    );
  }
}

class _BuyAmountInput extends StatelessWidget {
  _BuyAmountInput({Key? key, required this.isEnabled}) : super(key: key);

  final bool isEnabled;

  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    return StreamBuilder<Rational?>(
      initialData: makerFormBloc.buyAmount,
      stream: makerFormBloc.outBuyAmount,
      builder: (context, snapshot) {
        formatAmountInput(_textController, makerFormBloc.buyAmount);

        return SizedBox(
          height: 20,
          child: TextFormField(
            key: const Key('maker-buy-amount-input'),
            controller: _textController,
            enabled: isEnabled,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.end,
            inputFormatters: currencyInputFormatters,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: dexPageColors.activeText,
              decoration: TextDecoration.none,
            ),
            onChanged: (String value) {
              makerFormBloc.setBuyAmount(value);
            },
            decoration: const InputDecoration(
              hintText: '0.00',
              contentPadding: EdgeInsets.all(0),
              fillColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
          ),
        );
      },
    );
  }
}
