import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/bloc/fiat/models/fiat_price_info.dart';
import 'package:web_dex/bloc/fiat/models/i_currency.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/views/fiat/custom_fiat_input_field.dart';
import 'package:web_dex/views/fiat/fiat_currency_item.dart';
import 'package:web_dex/views/fiat/fiat_icon.dart';

class FiatInputs extends StatefulWidget {
  const FiatInputs({
    required this.initialFiat,
    required this.initialFiatAmount,
    required this.selectedAsset,
    required this.selectedAssetAddress,
    required this.selectedAssetPubkeys,
    required this.fiatList,
    required this.coinList,
    required this.isLoggedIn,
    required this.onFiatCurrencyChanged,
    required this.onCoinChanged,
    required this.onFiatAmountUpdate,
    super.key,
    this.selectedPaymentMethodPrice,
    this.fiatMinAmount,
    this.fiatMaxAmount,
    this.boundariesError,
    this.onSourceAddressChanged,
  });

  final FiatCurrency initialFiat;
  final Decimal? initialFiatAmount;
  final CryptoCurrency selectedAsset;
  final Iterable<FiatCurrency> fiatList;
  final Iterable<CryptoCurrency> coinList;
  final FiatPriceInfo? selectedPaymentMethodPrice;
  final bool isLoggedIn;
  final PubkeyInfo? selectedAssetAddress;
  final Decimal? fiatMinAmount;
  final Decimal? fiatMaxAmount;
  final String? boundariesError;
  final void Function(FiatCurrency) onFiatCurrencyChanged;
  final void Function(CryptoCurrency) onCoinChanged;
  final void Function(String?) onFiatAmountUpdate;

  final AssetPubkeys? selectedAssetPubkeys;
  final ValueChanged<PubkeyInfo?>? onSourceAddressChanged;

  @override
  FiatInputsState createState() => FiatInputsState();
}

class FiatInputsState extends State<FiatInputs> {
  TextEditingController fiatController = TextEditingController();

  @override
  void dispose() {
    fiatController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fiatController.text = widget.initialFiatAmount?.toString() ?? '';
  }

  @override
  void didUpdateWidget(FiatInputs oldWidget) {
    super.didUpdateWidget(oldWidget);

    final Decimal? newFiatAmount = widget.initialFiatAmount;

    // Convert the current text to Decimal for comparison
    final Decimal currentFiatAmount =
        Decimal.tryParse(fiatController.text) ?? Decimal.zero;

    // Compare using Decimal values
    if (newFiatAmount != currentFiatAmount) {
      final newFiatAmountText = newFiatAmount?.toString() ?? '';
      fiatController
        ..text = newFiatAmountText
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: newFiatAmountText.length),
        );
    }
  }

  void changeFiat(FiatCurrency? newValue) {
    if (newValue == null) return;

    widget.onFiatCurrencyChanged(newValue);
  }

  void changeCoin(CryptoCurrency? newValue) {
    if (newValue == null) return;

    widget.onCoinChanged(newValue);
  }

  void fiatAmountChanged(String? newValue) {
    widget.onFiatAmountUpdate(newValue);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: refactor currency type to use AssetId/Asset to avoid
    // conversions like this in the build method :(
    final sdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    final selectedAsset = widget.selectedAsset.toAsset(sdk);
    final priceInfo = widget.selectedPaymentMethodPrice;
    final priceDecimals = selectedAsset.id.chainId.decimals ?? 8;

    final coinAmount = priceInfo?.coinAmount.toStringAsFixed(priceDecimals);
    final fiatListLoading = widget.fiatList.length <= 1;
    final coinListLoading = widget.coinList.length <= 1;

    final minFiatAmount = widget.fiatMinAmount?.toStringAsFixed(2);
    final maxFiatAmount = widget.fiatMaxAmount?.toStringAsFixed(2);
    final boundariesString =
        widget.fiatMaxAmount == null && widget.fiatMinAmount == null
            ? ''
            : '(${minFiatAmount ?? '1'} - ${maxFiatAmount ?? '∞'})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFiatInputField(
          key: const Key('fiat-amount-form-field'),
          controller: fiatController,
          hintText: '${LocaleKeys.enterAmount.tr()} $boundariesString',
          onTextChanged: fiatAmountChanged,
          label: Text(LocaleKeys.spend.tr()),
          assetButton: FiatCurrencyItem(
            key: const Key('fiat-onramp-fiat-dropdown'),
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            disabled: fiatListLoading,
            currency: widget.initialFiat,
            icon: FiatIcon(
              key: Key('fiat_icon_${widget.initialFiat.getAbbr()}'),
              symbol: widget.initialFiat.getAbbr(),
            ),
            onTap: () => _showAssetSelectionDialog('fiat'),
            isListTile: false,
          ),
          inputError: widget.boundariesError,
        ),
        AnimatedContainer(
          duration: Duration.zero,
          height: widget.boundariesError == null ? 0 : 8,
        ),
        Card(
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.onSurface,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LocaleKeys.youReceive.tr()),
                        AutoScrollText(
                          text: fiatController.text.isEmpty || priceInfo == null
                              ? '0.00'
                              : coinAmount ?? '0.00',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: FiatCurrencyItem(
                      key: const Key('fiat-onramp-coin-dropdown'),
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      disabled: coinListLoading,
                      currency: widget.selectedAsset,
                      icon: Icon(_getDefaultAssetIcon('coin')),
                      onTap: () => _showAssetSelectionDialog('coin'),
                      isListTile: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isLoggedIn) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SourceAddressField(
                  asset: selectedAsset,
                  pubkeys: widget.selectedAssetPubkeys,
                  selectedAddress: widget.selectedAssetAddress,
                  onChanged: widget.onSourceAddressChanged,
                  isLoading: widget.selectedAssetAddress == null,
                  showBalanceIndicator: false,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showAssetSelectionDialog(String type) {
    final isFiat = type == 'fiat';
    final icon = Icon(_getDefaultAssetIcon(type));

    if (isFiat) {
      _showSelectionDialog<FiatCurrency>(
        context: context,
        title: LocaleKeys.selectFiat.tr(),
        itemList: widget.fiatList,
        icon: icon,
        onItemSelected: changeFiat,
      );
    } else {
      _showSelectionDialog<CryptoCurrency>(
        context: context,
        title: LocaleKeys.selectCoin.tr(),
        itemList: widget.coinList,
        icon: icon,
        onItemSelected: changeCoin,
      );
    }
  }

  void _showSelectionDialog<C extends ICurrency>({
    required BuildContext context,
    required String title,
    required Iterable<C> itemList,
    required Widget icon,
    required void Function(C) onItemSelected,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          key: const Key('fiat-onramp-currency-dialog'),
          title: Text(title),
          content: SizedBox(
            width: 450,
            child: ListView.builder(
              key: const Key('fiat-onramp-currency-list'),
              shrinkWrap: true,
              itemCount: itemList.length,
              itemBuilder: (BuildContext context, int index) {
                final item = itemList.elementAt(index);
                return FiatCurrencyItem(
                  key: Key('fiat-onramp-currency-item-${item.symbol}'),
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  disabled: false,
                  currency: item,
                  icon: icon,
                  onTap: () {
                    onItemSelected(item);
                    Navigator.of(context).pop();
                  },
                  isListTile: true,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

IconData _getDefaultAssetIcon(String type) {
  return type == 'fiat' ? Icons.attach_money : Icons.monetization_on;
}
