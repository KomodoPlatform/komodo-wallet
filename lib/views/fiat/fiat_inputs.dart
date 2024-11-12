import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dex/bloc/fiat/base_fiat_provider.dart';
import 'package:web_dex/bloc/fiat/fiat_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/coin_icon.dart';
import 'package:web_dex/views/fiat/fiat_icon.dart';

// TODO(@takenagain): When `dev` is merged into `main`, please refactor this
// to use the `CoinIcon` widget. I'm leaving this unchanged for now to avoid
// merge conflicts with your fiat onramp overhaul.
class FiatInputs extends StatefulWidget {
  final Function(Currency, Currency) onUpdate;
  final Function(String?) onFiatAmountUpdate;
  final Currency initialFiat;
  final Currency initialCoin;
  final Map<String, dynamic>? selectedPaymentMethodPrice;
  final bool isLoggedIn;
  final String? receiveAddress;
  final double? fiatMinAmount;
  final double? fiatMaxAmount;
  final String? boundariesError;

  const FiatInputs({
    required this.onUpdate,
    required this.onFiatAmountUpdate,
    required this.initialFiat,
    required this.initialCoin,
    required this.receiveAddress,
    required this.isLoggedIn,
    this.selectedPaymentMethodPrice,
    this.fiatMinAmount,
    this.fiatMaxAmount,
    this.boundariesError,
  });

  @override
  FiatInputsState createState() => FiatInputsState();
}

class FiatInputsState extends State<FiatInputs> {
  TextEditingController fiatController = TextEditingController();

  late Currency selectedFiat;
  late Currency selectedCoin;
  List<Currency> fiatList = [];
  List<Currency> coinList = [];

  // As part of refactoring, we need to move this to a bloc state. In this
  // instance, we wanted to show the loading indicator in the parent widget
  // but that's not possible with the current implementation.
  bool get isLoading => fiatList.length < 2 || coinList.length < 2;

  @override
  void dispose() {
    fiatController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      selectedFiat = widget.initialFiat;
      selectedCoin = widget.initialCoin;
      fiatList = [widget.initialFiat];
      coinList = [widget.initialCoin];
    });
    initFiatList();
    initCoinList();
  }

  void initFiatList() async {
    final list = await fiatRepository.getFiatList();
    if (mounted) {
      setState(() {
        fiatList = list;
      });
    }
  }

  void initCoinList() async {
    final list = await fiatRepository.getCoinList();
    if (mounted) {
      setState(() {
        coinList = list;
      });
    }
  }

  void updateParent() {
    widget.onUpdate(
      selectedFiat,
      selectedCoin,
    );
  }

  void changeFiat(Currency? newValue) {
    if (newValue == null) return;

    if (mounted) {
      setState(() {
        selectedFiat = newValue;
      });
    }
    updateParent();
  }

  void changeCoin(Currency? newValue) {
    if (newValue == null) return;

    if (mounted) {
      setState(() {
        selectedCoin = newValue;
      });
    }
    updateParent();
  }

  void fiatAmountChanged(String? newValue) {
    setState(() {});
    widget.onFiatAmountUpdate(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final priceInfo = widget.selectedPaymentMethodPrice;

    final coinAmount = priceInfo != null && priceInfo.isNotEmpty
        ? priceInfo['coin_amount']
        : null;
    final fiatListLoading = fiatList.length <= 1;
    final coinListLoading = coinList.length <= 1;

    final boundariesString = widget.fiatMaxAmount == null &&
            widget.fiatMinAmount == null
        ? ''
        : '(${widget.fiatMinAmount ?? '1'} - ${widget.fiatMaxAmount ?? '∞'})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFiatInputField(
          controller: fiatController,
          hintText: '${LocaleKeys.enterAmount.tr()} $boundariesString',
          onTextChanged: fiatAmountChanged,
          label: Text(LocaleKeys.spend.tr()),
          assetButton: _buildCurrencyItem(
            disabled: fiatListLoading,
            currency: selectedFiat,
            icon: FiatIcon(
              key: Key('fiat_icon_${selectedFiat.symbol}'),
              symbol: selectedFiat.symbol,
            ),
            onTap: () => _showAssetSelectionDialog('fiat'),
            isListTile: false,
          ),
          inputError: widget.boundariesError,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 00),
          height: widget.boundariesError == null ? 0 : 8,
        ),
        Card(
          margin: const EdgeInsets.all(0),
          color: Theme.of(context).colorScheme.onSurface,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LocaleKeys.youReceive.tr()),
                      Text(
                        fiatController.text.isEmpty || priceInfo == null
                            ? '0.00'
                            : coinAmount ?? LocaleKeys.unknown.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: _buildCurrencyItem(
                      disabled: coinListLoading,
                      currency: selectedCoin,
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
          AddressBar(receiveAddress: widget.receiveAddress),
        ],
      ],
    );
  }

  IconData _getDefaultAssetIcon(String type) {
    return type == 'fiat' ? Icons.attach_money : Icons.monetization_on;
  }

  void _showAssetSelectionDialog(String type) {
    final isFiat = type == 'fiat';
    List<Currency> itemList = isFiat ? fiatList : coinList;
    final icon = Icon(_getDefaultAssetIcon(type));
    Function(Currency) onItemSelected = isFiat ? changeFiat : changeCoin;

    _showSelectionDialog(
      context: context,
      title: isFiat ? LocaleKeys.selectFiat.tr() : LocaleKeys.selectCoin.tr(),
      itemList: itemList,
      icon: icon,
      onItemSelected: onItemSelected,
    );
  }

  void _showSelectionDialog({
    required BuildContext context,
    required String title,
    required List<Currency> itemList,
    required Widget icon,
    required Function(Currency) onItemSelected,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 450,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: itemList.length,
              itemBuilder: (BuildContext context, int index) {
                final item = itemList[index];
                return _buildCurrencyItem(
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

  Widget _buildCurrencyItem({
    required bool disabled,
    required Currency currency,
    required Widget icon,
    required VoidCallback onTap,
    required bool isListTile,
  }) {
    return FutureBuilder<bool>(
      future: currency.isFiat
          ? Future.value(true)
          : checkIfAssetExists(currency.symbol),
      builder: (context, snapshot) {
        final assetExists = snapshot.connectionState == ConnectionState.done
            ? snapshot.data ?? false
            : null;
        return isListTile
            ? _buildListTile(
                currency: currency,
                icon: icon,
                assetExists: assetExists,
                onTap: onTap,
              )
            : _buildButton(
                enabled: !disabled,
                currency: currency,
                icon: icon,
                assetExists: assetExists,
                onTap: onTap,
              );
      },
    );
  }

  Widget _getAssetIcon({
    required Currency currency,
    required Widget icon,
    bool? assetExists,
    required VoidCallback onTap,
  }) {
    double size = 36.0;

    if (currency.isFiat) {
      return FiatIcon(symbol: currency.symbol);
    }

    if (assetExists != null && assetExists) {
      return CoinIcon(currency.symbol, size: size);
    } else {
      return icon;
    }
  }

  Widget _buildListTile({
    required Currency currency,
    required Widget icon,
    bool? assetExists,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: _getAssetIcon(
        currency: currency,
        icon: icon,
        assetExists: assetExists,
        onTap: onTap,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            '${currency.name}${currency.chainType != null ? ' (${getCoinTypeName(currency.chainType!)})' : ''}',
          ),
          Text(currency.symbol),
        ],
      ),
      onTap: onTap,
    );
  }

  Color get foregroundColor => Theme.of(context).colorScheme.onSurfaceVariant;

  Widget _buildButton({
    required bool enabled,
    required Currency? currency,
    required Widget icon,
    bool? assetExists,
    required VoidCallback onTap,
  }) {
    // TODO: Refactor so that [Currency] holds an enum for fiat/coin or create
    // a separate class for fiat/coin that extend the same base class.
    final isFiat = currency?.isFiat ?? false;

    return FilledButton.icon(
      onPressed: enabled ? onTap : null,
      label: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                (isFiat ? currency?.getAbbr() : currency?.name) ??
                    (isFiat
                        ? LocaleKeys.selectFiat.tr()
                        : LocaleKeys.selectCoin.tr()),
                style: DefaultTextStyle.of(context).style.copyWith(
                      fontWeight: FontWeight.w500,
                      color: enabled
                          ? foregroundColor
                          : foregroundColor.withOpacity(0.5),
                    ),
              ),
              if (!isFiat && currency != null)
                Text(
                  currency.chainType != null
                      ? getCoinTypeName(currency.chainType!)
                      : '',
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: enabled
                            ? foregroundColor.withOpacity(0.5)
                            : foregroundColor.withOpacity(0.25),
                      ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 28,
            color: foregroundColor.withOpacity(enabled ? 1 : 0.5),
          ),
        ],
      ),
      style: (Theme.of(context).filledButtonTheme.style ?? const ButtonStyle())
          .copyWith(
        backgroundColor: WidgetStateProperty.all<Color>(
            Theme.of(context).colorScheme.onSurface),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        ),
        shape: WidgetStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      icon: currency == null
          ? Icon(_getDefaultAssetIcon(isFiat ? 'fiat' : 'coin'))
          : _getAssetIcon(
              currency: currency,
              icon: icon,
              assetExists: assetExists,
              onTap: onTap,
            ),
    );
  }
}

class AddressBar extends StatelessWidget {
  const AddressBar({
    super.key,
    required this.receiveAddress,
  });

  final String? receiveAddress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onTap: () => copyToClipBoard(context, receiveAddress!),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (receiveAddress != null && receiveAddress!.isNotEmpty)
                  const Icon(Icons.copy, size: 16)
                else
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    truncateMiddleSymbols(receiveAddress ?? ''),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomFiatInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? label;
  final Function(String?) onTextChanged;
  final bool readOnly;
  final Widget assetButton;
  final String? inputError;

  const CustomFiatInputField({
    required this.controller,
    required this.hintText,
    required this.onTextChanged,
    this.label,
    this.readOnly = false,
    required this.assetButton,
    this.inputError,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;

    final inputStyle = Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w300,
          color: textColor,
          letterSpacing: 1.1,
        );

    InputDecoration inputDecoration = InputDecoration(
      label: label,
      labelStyle: inputStyle,
      fillColor: Theme.of(context).colorScheme.onSurface,
      floatingLabelStyle:
          Theme.of(context).inputDecorationTheme.floatingLabelStyle,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      hintText: hintText,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(4),
          topLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      errorText: inputError,
      errorMaxLines: 1,
      helperText: '',
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        TextField(
          autofocus: true,
          controller: controller,
          style: inputStyle,
          decoration: inputDecoration,
          readOnly: readOnly,
          onChanged: onTextChanged,
          inputFormatters: [FilteringTextInputFormatter.allow(numberRegExp)],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        Positioned(
          right: 16,
          bottom: 26,
          top: 2,
          child: assetButton,
        ),
      ],
    );
  }
}
