import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item.dart';

class CoinAmountMobile extends StatelessWidget {
  const CoinAmountMobile({
    Key? key,
    required this.coinAbbr,
    required this.amount,
  }) : super(key: key);
  final String coinAbbr;
  final Rational amount;

  @override
  Widget build(BuildContext context) {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    final Coin? coin = coinsRepository.getCoin(coinAbbr);

    if (coin == null) return const SizedBox.shrink();

    return CoinItem(coin: coin, amount: amount.toDouble());
  }
}
