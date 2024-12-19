import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
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
    required this.isMobile,
    required this.selectWidget,
    required this.onClickSwapButton,
    required this.coin,
    super.key,
  });

  final bool isMobile;
  final Coin coin;
  final void Function(CoinPageType) selectWidget;
  final VoidCallback? onClickSwapButton;

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? CoinDetailsCommonButtonsMobileLayout(
            coin: coin,
            isMobile: isMobile,
            selectWidget: selectWidget,
            clickSwapButton: onClickSwapButton,
            context: context,
          )
        : CoinDetailsCommonButtonsDesktopLayout(
            isMobile: isMobile,
            coin: coin,
            selectWidget: selectWidget,
            clickSwapButton: onClickSwapButton,
            context: context,
          );
  }
}

class CoinDetailsCommonButtonsMobileLayout extends StatelessWidget {
  const CoinDetailsCommonButtonsMobileLayout({
    required this.coin,
    required this.isMobile,
    required this.selectWidget,
    required this.clickSwapButton,
    required this.context,
    super.key,
  });

  final Coin coin;
  final bool isMobile;
  final void Function(CoinPageType p1) selectWidget;
  final VoidCallback? clickSwapButton;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: coin.protocolData?.contractAddress.isNotEmpty ?? false,
          child: ContractAddressButton(coin),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: CoinDetailsSendButton(
                isMobile: isMobile,
                coin: coin,
                selectWidget: selectWidget,
                context: context,
              ),
            ),
            const SizedBox(width: 15),
            Flexible(
              child: CoinDetailsReceiveButton(
                isMobile: isMobile,
                coin: coin,
                selectWidget: selectWidget,
                context: context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBitrefillIntegrationEnabled)
              Flexible(
                child: BitrefillButton(
                  key: Key(
                    'coin-details-bitrefill-button-${coin.abbr.toLowerCase()}',
                  ),
                  coin: coin,
                  onPaymentRequested: (_) => selectWidget(CoinPageType.send),
                ),
              ),
            if (isBitrefillIntegrationEnabled) const SizedBox(width: 15),
            if (!coin.walletOnly)
              Flexible(
                child: CoinDetailsSwapButton(
                  isMobile: isMobile,
                  coin: coin,
                  onClickSwapButton: clickSwapButton,
                  context: context,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class CoinDetailsCommonButtonsDesktopLayout extends StatelessWidget {
  const CoinDetailsCommonButtonsDesktopLayout({
    required this.isMobile,
    required this.coin,
    required this.selectWidget,
    required this.clickSwapButton,
    required this.context,
    super.key,
  });

  final bool isMobile;
  final Coin coin;
  final void Function(CoinPageType p1) selectWidget;
  final VoidCallback? clickSwapButton;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: CoinDetailsSendButton(
            isMobile: isMobile,
            coin: coin,
            selectWidget: selectWidget,
            context: context,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 21),
          constraints: const BoxConstraints(maxWidth: 120),
          child: CoinDetailsReceiveButton(
            isMobile: isMobile,
            coin: coin,
            selectWidget: selectWidget,
            context: context,
          ),
        ),
        if (!coin.walletOnly && !kIsWalletOnly)
          Container(
            margin: const EdgeInsets.only(left: 21),
            constraints: const BoxConstraints(maxWidth: 120),
            child: CoinDetailsSwapButton(
              isMobile: isMobile,
              coin: coin,
              onClickSwapButton: clickSwapButton,
              context: context,
            ),
          ),
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
          ),
        ),
      ],
    );
  }
}

class CoinDetailsReceiveButton extends StatelessWidget {
  const CoinDetailsReceiveButton({
    required this.isMobile,
    required this.coin,
    required this.selectWidget,
    required this.context,
    super.key,
  });

  final bool isMobile;
  final Coin coin;
  final void Function(CoinPageType p1) selectWidget;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
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
}

class CoinDetailsSendButton extends StatelessWidget {
  const CoinDetailsSendButton({
    required this.isMobile,
    required this.coin,
    required this.selectWidget,
    required this.context,
    super.key,
  });

  final bool isMobile;
  final Coin coin;
  final void Function(CoinPageType p1) selectWidget;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
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
}

class CoinDetailsSwapButton extends StatelessWidget {
  const CoinDetailsSwapButton({
    required this.isMobile,
    required this.coin,
    required this.onClickSwapButton,
    required this.context,
    super.key,
  });

  final bool isMobile;
  final Coin coin;
  final VoidCallback? onClickSwapButton;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final currentWallet = context.watch<AuthBloc>().state.currentUser?.wallet;
    if (currentWallet?.config.type != WalletType.iguana &&
        currentWallet?.config.type != WalletType.hdwallet) {
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
      onPressed: coin.isSuspended ? null : onClickSwapButton,
    );
  }
}
