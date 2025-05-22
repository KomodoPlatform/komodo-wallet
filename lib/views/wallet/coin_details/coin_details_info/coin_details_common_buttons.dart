import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/views/bitrefill/bitrefill_button.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/coin_addresses.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/contract_address_button.dart';
import 'package:web_dex/views/wallet/coin_details/coin_page_type.dart';

class CoinDetailsCommonButtons extends StatelessWidget {
  const CoinDetailsCommonButtons({
    required this.selectWidget,
    required this.onClickSwapButton,
    required this.coin,
    super.key,
  });

  final Coin coin;
  final void Function(CoinPageType) selectWidget;
  final VoidCallback? onClickSwapButton;

  @override
  Widget build(BuildContext context) {
    return ResponsiveButtonLayout(
      coin: coin,
      selectWidget: selectWidget,
      onClickSwapButton: onClickSwapButton,
    );
  }
}

class ResponsiveButtonLayout extends StatelessWidget {
  const ResponsiveButtonLayout({
    required this.coin,
    required this.selectWidget,
    required this.onClickSwapButton,
    super.key,
  });

  final Coin coin;
  final void Function(CoinPageType) selectWidget;
  final VoidCallback? onClickSwapButton;

  @override
  Widget build(BuildContext context) {
    final hasContractAddress =
        coin.protocolData?.contractAddress.isNotEmpty ?? false;
    final double spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrowLayout = constraints.maxWidth < 600;
        final List<Widget> buttons = [];

        // Add send button
        buttons.add(
          CoinDetailsSendButton(
            coin: coin,
            selectWidget: selectWidget,
            context: context,
          ),
        );

        // Add receive button
        buttons.add(
          CoinDetailsReceiveButton(
            coin: coin,
            selectWidget: selectWidget,
            context: context,
          ),
        );

        // Add message signing button
        buttons.add(
          CoinDetailsMessageSigningButton(
            coin: coin,
            selectWidget: selectWidget,
            context: context,
          ),
        );

        // Add swap button if needed
        if (!coin.walletOnly && !kIsWalletOnly) {
          buttons.add(
            CoinDetailsSwapButton(
              coin: coin,
              onClickSwapButton: onClickSwapButton,
              context: context,
            ),
          );
        }

        if (isBitrefillIntegrationEnabled) {
          buttons.add(
            BitrefillButton(
              key: Key(
                  'coin-details-bitrefill-button-${coin.abbr.toLowerCase()}'),
              coin: coin,
              onPaymentRequested: (_) => selectWidget(CoinPageType.send),
            ),
          );
        }

        // Add contract address button if the coin has a contract address
        if (hasContractAddress) {
          buttons.add(
            ContractAddressButton(
              coin,
              key: const Key('coin-details-contract-address-button'),
            ),
          );
        }

        // // Determine button height based on layout
        final buttonHeight = isNarrowLayout ? 52.0 : 48.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.start,
          children: buttons
              .map(
                (button) => IntrinsicWidth(
                  child: SizedBox(
                    height: buttonHeight,
                    child: button,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class CoinDetailsReceiveButton extends StatelessWidget {
  const CoinDetailsReceiveButton({
    required this.coin,
    required this.selectWidget,
    required this.context,
    super.key,
  });

  final Coin coin;
  final void Function(CoinPageType p1) selectWidget;
  final BuildContext context;

  Future<void> _handleReceive(BuildContext context) async {
    // Get coin addresses bloc from the parent widget
    final addressesBloc = context.read<CoinAddressesBloc>();
    final addresses = addressesBloc.state.addresses;

    final selectedAddress = await showAddressSearch(
      context,
      addresses: addresses,
      assetNameLabel: coin.abbr,
    );

    if (selectedAddress != null && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => PubkeyReceiveDialog(
          coin: coin,
          address: selectedAddress,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAddresses =
        context.watch<CoinAddressesBloc>().state.addresses.isNotEmpty;
    final ThemeData themeData = Theme.of(context);

    return UiPrimaryButton.flexible(
      key: const Key('coin-details-receive-button'),
      // height: isNarrowLayout ? 52 : 40,
      prefix: SvgPicture.asset(
        '$assetsPath/others/receive.svg',
      ),
      textStyle: themeData.textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: themeData.colorScheme.tertiary,
      onPressed: coin.isSuspended || !hasAddresses
          ? null
          : () => _handleReceive(context),
      optimisticEnabledDuration: const Duration(seconds: 5),
      text: LocaleKeys.receive.tr(),
    );
  }
}

class AddressListItem extends StatelessWidget {
  const AddressListItem({
    super.key,
    required this.address,
    required this.coin,
  });

  final PubkeyInfo address;
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  address.formatted,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${address.balance.spendable} ${coin.name} available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoinDetailsSendButton extends StatelessWidget {
  const CoinDetailsSendButton({
    required this.coin,
    required this.selectWidget,
    required this.context,
    super.key,
  });

  final Coin coin;
  final void Function(CoinPageType p1) selectWidget;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return UiPrimaryButton.flexible(
      key: const Key('coin-details-send-button'),
      prefix: Container(
        padding: const EdgeInsets.only(right: 14),
        child: SvgPicture.asset(
          '$assetsPath/others/send.svg',
        ),
      ),
      textStyle: themeData.textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: themeData.colorScheme.tertiary,
      optimisticEnabledDuration: const Duration(seconds: 5),
      onPressed: coin.isSuspended
          //TODO!: coin.balance == 0
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
    required this.coin,
    required this.onClickSwapButton,
    required this.context,
    super.key,
  });

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

    return UiPrimaryButton.flexible(
      key: const Key('coin-details-swap-button'),
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

class CoinDetailsMessageSigningButton extends StatelessWidget {
  const CoinDetailsMessageSigningButton({
    required this.coin,
    required this.selectWidget,
    required this.context,
    super.key,
  });

  final Coin coin;
  final void Function(CoinPageType) selectWidget;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final hasAddresses =
        context.watch<CoinAddressesBloc>().state.addresses.isNotEmpty;
    final ThemeData themeData = Theme.of(context);

    return UiPrimaryButton.flexible(
      key: const Key('coin-details-sign-message-button'),
      prefix: Icon(Icons.fingerprint),
      textStyle: themeData.textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: themeData.colorScheme.tertiary,
      optimisticEnabledDuration: const Duration(seconds: 5),
      onPressed: coin.isSuspended || !hasAddresses
          ? null
          : () {
              selectWidget(CoinPageType.signMessage);
            },
      text: LocaleKeys.signMessage.tr(),
    );
  }
}
