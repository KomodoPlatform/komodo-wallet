import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rational/rational.dart';
import 'package:komodo_wallet/app_config/app_config.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_repo.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_item.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_item_size.dart';

class TradingDetailsCoinPair extends StatelessWidget {
  const TradingDetailsCoinPair({
    Key? key,
    required this.baseCoin,
    required this.baseAmount,
    required this.relCoin,
    required this.relAmount,
  }) : super(key: key);
  final String baseCoin;
  final Rational baseAmount;
  final String relCoin;
  final Rational relAmount;
  @override
  Widget build(BuildContext context) {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    final Coin? coinBase = coinsRepository.getCoin(baseCoin);
    final Coin? coinRel = coinsRepository.getCoin(relCoin);

    if (coinBase == null || coinRel == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.currentGlobal.colorScheme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: CoinItem(
              coin: coinBase,
              amount: baseAmount.toDouble(),
              size: CoinItemSize.large,
            ),
          ),
          Column(
            children: [
              SvgPicture.asset(
                '$assetsPath/ui_icons/arrows.svg',
              ),
            ],
          ),
          Flexible(
            child: CoinItem(
              coin: coinRel,
              amount: relAmount.toDouble(),
              size: CoinItemSize.large,
            ),
          ),
        ],
      ),
    );
  }
}
