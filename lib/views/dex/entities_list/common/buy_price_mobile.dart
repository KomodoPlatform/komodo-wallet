import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class BuyPriceMobile extends StatelessWidget {
  const BuyPriceMobile({
    Key? key,
    required this.buyCoin,
    required this.sellAmount,
    required this.buyAmount,
  }) : super(key: key);
  final String buyCoin;
  final Rational sellAmount;
  final Rational buyAmount;

  @override
  Widget build(BuildContext context) {
    final tradingEntitiesBloc =
        RepositoryProvider.of<TradingEntitiesBloc>(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          Text(
            LocaleKeys.buyPrice.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
          Text(
            '${formatDexAmt(tradingEntitiesBloc.getPriceFromAmount(sellAmount, buyAmount))} ${Coin.normalizeAbbr(buyCoin)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
