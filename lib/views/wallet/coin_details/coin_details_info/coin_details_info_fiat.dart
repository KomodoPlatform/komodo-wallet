import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui/src/defi/asset/trend_percentage_text.dart';
import 'package:app_theme/src/dark/theme_custom_dark.dart';
import 'package:app_theme/src/light/theme_custom_light.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/widgets/coin_fiat_balance.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/utils/extensions/legacy_coin_migration_extensions.dart';

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
        _buildPriceValue(isMobile, context),
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
        _buildChangeValue(isMobile, context),
      ],
    );
  }

  Widget _buildPriceValue(bool isMobile, BuildContext context) {
    // Use the same approach as main wallet page
    final sdk = context.read<KomodoDefiSdk>();
    final double? usdPrice = coin.lastKnownUsdPrice(sdk);
    
    if (usdPrice == null || usdPrice == 0) return const SizedBox();

    final TextStyle style = TextStyle(
      fontSize: isMobile ? 16 : 14,
      fontWeight: FontWeight.w700,
    );

    return Row(
      children: [
        Text('\$', style: style),
        Text(
          formatAmt(usdPrice),
          key: Key('fiat-price-${coin.abbr.toLowerCase()}'),
          style: style,
        ),
      ],
    );
  }

  Widget _buildChangeValue(bool isMobile, BuildContext context) {
    return BlocBuilder<CoinsBloc, CoinsState>(
      buildWhen: (previous, current) {
        return previous.get24hChangeForAsset(coin.id) != 
               current.get24hChangeForAsset(coin.id);
      },
      builder: (context, state) {
        final change24hPercent = state.get24hChangeForAsset(coin.id);
        
        final theme = Theme.of(context);
        final themeCustom = Theme.of(context).brightness == Brightness.dark
            ? theme.extension<ThemeCustomDark>()!
            : theme.extension<ThemeCustomLight>()!;

        return TrendPercentageText(
          percentage: change24hPercent,
          textStyle: TextStyle(
            fontSize: isMobile ? 16 : 14,
            fontWeight: FontWeight.w700,
          ),
          upColor: themeCustom.increaseColor,
          downColor: themeCustom.decreaseColor,
          showIcon: false,
          noValueText: '-',
        );
      },
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
