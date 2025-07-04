import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/widgets/coin_fiat_balance.dart';
import 'package:komodo_wallet/shared/widgets/coin_fiat_change.dart';
import 'package:komodo_wallet/shared/widgets/coin_fiat_price.dart';

class CoinDetailsInfoFiat extends StatelessWidget {
  const CoinDetailsInfoFiat({
    Key? key,
    required this.coin,
    required this.isMobile,
  }) : super(key: key);
  final bool isMobile;
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isMobile ? null : const EdgeInsets.fromLTRB(0, 6, 4, 0),
      child: Flex(
        direction: isMobile ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment:
            isMobile ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.end,
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (isMobile) _buildFiatBalance(context),
          _buildPrice(isMobile, context),
          if (!isMobile) const SizedBox(height: 6),
          _buildChange(isMobile, context),
        ],
      ),
    );
  }

  Widget _buildPrice(bool isMobile, BuildContext context) {
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.price.tr(),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
        isMobile ? const SizedBox(height: 3) : const SizedBox(width: 10),
        CoinFiatPrice(
          coin,
          style: TextStyle(
            fontSize: isMobile ? 16 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildChange(bool isMobile, BuildContext context) {
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.change24h.tr(),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
        isMobile ? const SizedBox(height: 3) : const SizedBox(width: 10),
        CoinFiatChange(
          coin,
          style: TextStyle(
              fontSize: isMobile ? 16 : 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildFiatBalance(BuildContext context) {
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.fiatBalance.tr(),
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
        ),
        const SizedBox(height: 3),
        CoinFiatBalance(
          coin,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
