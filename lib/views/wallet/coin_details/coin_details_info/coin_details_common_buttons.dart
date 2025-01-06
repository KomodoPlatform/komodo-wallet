import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';
import 'package:web_dex/views/bitrefill/bitrefill_button.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/contract_address_button.dart';
import 'package:web_dex/views/wallet/coin_details/coin_page_type.dart';
import 'package:web_dex/views/wallet/coin_details/faucet/faucet_button.dart';

class CoinDetailsCommonButtons extends StatelessWidget {
  const CoinDetailsCommonButtons({
    Key? key,
    required this.isMobile,
    required this.selectWidget,
    required this.clickSwapButton,
    required this.coin,
  }) : super(key: key);

  final bool isMobile;
  final Coin coin;
  final void Function(CoinPageType) selectWidget;
  final VoidCallback? clickSwapButton;

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? _buildMobileButtons(context)
        : _buildDesktopButtons(context);
  }

  Widget _buildDesktopButtons(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: _buildSendButton(context),
        ),
        Container(
          margin: const EdgeInsets.only(left: 21),
          constraints: const BoxConstraints(maxWidth: 120),
          child: _buildReceiveButton(context),
        ),
        if (!coin.walletOnly && !kIsWalletOnly)
          Container(
              margin: const EdgeInsets.only(left: 21),
              constraints: const BoxConstraints(maxWidth: 120),
              child: _buildSwapButton(context)),
        if (coin.hasFaucet)
          Container(
            margin: const EdgeInsets.only(left: 21),
            constraints: const BoxConstraints(maxWidth: 120),
            child: FaucetButton(
              onPressed: () => selectWidget(CoinPageType.faucet),
            ),
          ),
        if (isBitrefillIntegrationEnabled)
          Container(
            margin: const EdgeInsets.only(left: 21),
            constraints: const BoxConstraints(maxWidth: 120),
            child: BitrefillButton(
              key: Key(
                'coin-details-bitrefill-button-${coin.abbr.toLowerCase()}',
              ),
              coin: coin,
              onPaymentRequested: (_) => selectWidget(CoinPageType.send),
            ),
          ),
        Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: coin.protocolData?.contractAddress.isNotEmpty ?? false
                  ? SizedBox(width: 230, child: ContractAddressButton(coin))
                  : null,
            ))
      ],
    );
  }

  Widget _buildMobileButtons(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: coin.protocolData?.contractAddress.isNotEmpty ?? false,
          child: ContractAddressButton(coin),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(child: _buildSendButton(context)),
            const SizedBox(width: 15),
            Flexible(child: _buildReceiveButton(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildSendButton(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return UiPrimaryButton(
      key: const Key('coin-details-send-button'),
      height: isMobile ? 52 : 40,
      prefix: Container(
        padding: const EdgeInsets.only(right: 14),
        child: SvgPicture.asset(
          '$assetsPath/others/send.svg',
        ),
      ),
      textStyle: themeData.textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: themeData.colorScheme.tertiary,
      onPressed: coin.isSuspended || coin.balance == 0
          ? null
          : () {
              selectWidget(CoinPageType.send);
            },
      text: LocaleKeys.send.tr(),
    );
  }

  Widget _buildReceiveButton(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return UiPrimaryButton(
      key: const Key('coin-details-receive-button'),
      height: isMobile ? 52 : 40,
      prefix: Container(
        padding: const EdgeInsets.only(right: 14),
        child: SvgPicture.asset(
          '$assetsPath/others/receive.svg',
        ),
      ),
      textStyle: themeData.textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: themeData.colorScheme.tertiary,
      onPressed: coin.isSuspended
          ? null
          : () {
              selectWidget(CoinPageType.receive);
            },
      text: LocaleKeys.receive.tr(),
    );
  }

  Widget _buildSwapButton(BuildContext context) {
    if (currentWalletBloc.wallet?.config.type != WalletType.iguana) {
      return const SizedBox.shrink();
    }

    final ThemeData themeData = Theme.of(context);
    return UiPrimaryButton(
      key: const Key('coin-details-swap-button'),
      height: isMobile ? 52 : 40,
      textStyle: themeData.textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: themeData.colorScheme.tertiary,
      text: LocaleKeys.swapCoin.tr(),
      prefix: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: SvgPicture.asset(
          '$assetsPath/others/swap.svg',
        ),
      ),
      onPressed: coin.isSuspended ? null : clickSwapButton,
    );
  }
}
