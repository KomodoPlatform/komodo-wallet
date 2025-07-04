import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:komodo_wallet/blocs/maker_form_bloc.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';
import 'package:komodo_wallet/views/dex/dex_helpers.dart';

class MakerFormSellAmount extends StatelessWidget {
  const MakerFormSellAmount(this.isEnabled, {Key? key}) : super(key: key);

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
            child: _SellAmountInput(
              key: const Key('maker-sell-amount'),
              isEnabled: isEnabled,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 18),
            child: _SellAmountFiat(),
          ),
        ],
      ),
    );
  }
}

class _SellAmountFiat extends StatelessWidget {
  const _SellAmountFiat();

  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    final TextStyle? textStyle = Theme.of(context).textTheme.bodySmall;
    return StreamBuilder<Rational?>(
      initialData: makerFormBloc.sellAmount,
      stream: makerFormBloc.outSellAmount,
      builder: (context, snapshot) {
        final amount = snapshot.data ?? Rational.zero;

        return StreamBuilder<Coin?>(
            initialData: makerFormBloc.sellCoin,
            stream: makerFormBloc.outSellCoin,
            builder: (context, snapshot) {
              final Coin? coin = snapshot.data;
              if (coin == null) return const SizedBox();

              return Text(
                getFormattedFiatAmount(context, coin.abbr, amount),
                style: textStyle,
              );
            });
      },
    );
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
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    return StreamBuilder<Rational?>(
      initialData: makerFormBloc.sellAmount,
      stream: makerFormBloc.outSellAmount,
      builder: (context, snapshot) {
        formatAmountInput(_textController, makerFormBloc.sellAmount);

        return SizedBox(
          height: 20,
          child: TextFormField(
            key: const Key('maker-sell-amount-input'),
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
              makerFormBloc.setSellAmount(value);
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
