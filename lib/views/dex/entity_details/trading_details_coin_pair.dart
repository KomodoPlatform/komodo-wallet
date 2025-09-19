import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:web_dex/shared/widgets/copied_text.dart';

class TradingDetailsCoinPair extends StatelessWidget {
  const TradingDetailsCoinPair({
    Key? key,
    required this.baseCoin,
    required this.baseAmount,
    required this.relCoin,
    required this.relAmount,
    this.swapId,
    this.isOrder = false,
  }) : super(key: key);
  final String baseCoin;
  final Rational baseAmount;
  final String relCoin;
  final Rational relAmount;
  final String? swapId;
  final bool isOrder;

  @override
  Widget build(BuildContext context) {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    final Coin? coinBase = coinsRepository.getCoin(baseCoin);
    final Coin? coinRel = coinsRepository.getCoin(relCoin);
    final String? swapId = this.swapId;
    final bool isOrder = this.isOrder;

    

    if (coinBase == null || coinRel == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.currentGlobal.colorScheme.surface,
      ),
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: 10),
          if (swapId != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              Flexible(
                child: CopiedText(
                  key: Key('uuid-${swapId}'),
                  text: isOrder ? 'Order UUID: ${swapId}' : 'Swap UUID: ${swapId}',
                  copiedValue: swapId,
                  isCopiedValueShown: false,
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  fontSize: 11,
                  iconSize: 14,
                  backgroundColor: theme.custom.subCardBackgroundColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
