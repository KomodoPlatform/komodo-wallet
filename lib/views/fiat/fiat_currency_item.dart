import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart' show AssetIcon;
import 'package:web_dex/bloc/fiat/models/i_currency.dart';
import 'package:web_dex/views/fiat/fiat_currency_list_tile.dart';
import 'package:web_dex/views/fiat/fiat_select_button.dart';

class FiatCurrencyItem extends StatelessWidget {
  const FiatCurrencyItem({
    required this.foregroundColor,
    required this.disabled,
    required this.currency,
    required this.icon,
    required this.onTap,
    required this.isListTile,
    super.key,
  });

  final Color foregroundColor;
  final bool disabled;
  final ICurrency currency;
  final Widget icon;
  final VoidCallback onTap;
  final bool isListTile;

  @override
  Widget build(BuildContext context) {
    final assetExists = AssetIcon.assetIconExists(currency.symbol);
    return isListTile
        ? FiatCurrencyListTile(
            currency: currency,
            icon: icon,
            onTap: onTap,
            assetExists: assetExists,
          )
        : FiatSelectButton(
            context: context,
            foregroundColor: foregroundColor,
            enabled: !disabled,
            currency: currency,
            icon: icon,
            onTap: onTap,
            assetExists: assetExists,
          );
  }
}
