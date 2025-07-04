import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/views/dex/common/front_plate.dart';
import 'package:web_dex/views/dex/common/trading_amount_field.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/headers/simple_form_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class WithdrawFormSourceItem extends StatelessWidget {
  const WithdrawFormSourceItem({
    super.key,
    required this.asset,
    required this.pubkeys,
    required this.selectedAddress,
    required this.onChanged,
    required this.amount,
    required this.onAmountChanged,
    required this.onMaxToggled,
    this.isLoading = false,
    this.isMaxAmount = false,
    this.networkError,
    this.onRetry,
    this.showBalanceIndicator = true,
  });

  final Asset asset;
  final AssetPubkeys? pubkeys;
  final PubkeyInfo? selectedAddress;
  final ValueChanged<PubkeyInfo?>? onChanged;
  final String amount;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<bool> onMaxToggled;
  final bool isLoading;
  final bool isMaxAmount;
  final String? networkError;
  final VoidCallback? onRetry;
  final bool showBalanceIndicator;

  @override
  Widget build(BuildContext context) {
    return FrontPlate(
      child: Column(
        children: [
          SimpleFormHeader(
            title: LocaleKeys.sendFrom.tr(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: AddressSelectInput(
              addresses: pubkeys?.keys ?? [],
              onAddressSelected: onChanged,
              selectedAddress: selectedAddress,
              assetName: asset.id.name,
              hint: LocaleKeys.selectAddress.tr(),
            ),
          ),
          WithdrawFormSwitcher(
            asset: asset,
            amount: amount,
            onAmountChanged: onAmountChanged,
            isMaxAmount: isMaxAmount,
            onMaxToggled: onMaxToggled,
          ),
        ],
      ),
    );
  }
}

class WithdrawFormSwitcher extends StatelessWidget {
  const WithdrawFormSwitcher({
    super.key,
    required this.asset,
    required this.amount,
    required this.onAmountChanged,
    required this.isMaxAmount,
    required this.onMaxToggled,
    this.padding = const EdgeInsets.only(top: 16, bottom: 12),
  });

  final Asset asset;
  final String amount;
  final ValueChanged<String> onAmountChanged;
  final bool isMaxAmount;
  final ValueChanged<bool> onMaxToggled;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WithdrawCoinGroup(
                asset: asset,
                key: const Key('withdraw-form-switcher'),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: WithdrawFormAmount(
                  amount: amount,
                  onAmountChanged: onAmountChanged,
                  isMaxAmount: isMaxAmount,
                  onMaxToggled: onMaxToggled,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WithdrawCoinGroup extends StatelessWidget {
  const WithdrawCoinGroup({
    Key? key,
    required this.asset,
  }) : super(key: key);

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssetIcon(asset.id, size: 40),
            const SizedBox(width: 9),
            _WithdrawCoinNameAndProtocol(asset: asset),
            const SizedBox(width: 9),
          ],
        ),
      ),
    );
  }
}

class _WithdrawCoinNameAndProtocol extends StatelessWidget {
  const _WithdrawCoinNameAndProtocol({
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          asset.id.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          asset.id.id,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class WithdrawFormAmount extends StatelessWidget {
  const WithdrawFormAmount({
    super.key,
    required this.amount,
    required this.onAmountChanged,
    required this.isMaxAmount,
    required this.onMaxToggled,
  });

  final String amount;
  final ValueChanged<String> onAmountChanged;
  final bool isMaxAmount;
  final ValueChanged<bool> onMaxToggled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18, top: 1),
      child: _WithdrawAmountInput(
        key: const Key('withdraw-amount'),
        amount: amount,
        onAmountChanged: onAmountChanged,
        isMaxAmount: isMaxAmount,
        onMaxToggled: onMaxToggled,
      ),
    );
  }
}

class _WithdrawAmountInput extends StatelessWidget {
  const _WithdrawAmountInput({
    Key? key,
    required this.amount,
    required this.onAmountChanged,
    required this.isMaxAmount,
    required this.onMaxToggled,
  }) : super(key: key);

  final String amount;
  final ValueChanged<String> onAmountChanged;
  final bool isMaxAmount;
  final ValueChanged<bool> onMaxToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => onMaxToggled(!isMaxAmount),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isMaxAmount
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  LocaleKeys.max.tr(),
                  style: TextStyle(
                    color: isMaxAmount
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TradingAmountField(
                controller: TextEditingController(
                  text: amount.isEmpty || amount == '0' ? '' : amount,
                )..selection = TextSelection.fromPosition(
                  TextPosition(offset: amount.isEmpty || amount == '0' ? 0 : amount.length),
                ),
                enabled: !isMaxAmount,
                onChanged: onAmountChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const _WithdrawBalanceField(balance: '≈ \$0.00'),
      ],
    );
  }
}

class _WithdrawBalanceField extends StatelessWidget {
  const _WithdrawBalanceField({this.balance});

  final String? balance;

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
    );

    if (balance == null || balance!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      '$balance',
      style: textStyle,
    );
  }
}